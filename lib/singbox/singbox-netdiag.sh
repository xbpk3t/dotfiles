#!/usr/bin/env bash
set -Eeuo pipefail

# 用法：
#   ./singbox-netdiag.sh
#   ./singbox-netdiag.sh --collect-only
#   ./singbox-netdiag.sh --repair-only
#   ./singbox-netdiag.sh --enforce-dns
#   ./singbox-netdiag.sh --dns 223.5.5.5 --service "Wi-Fi"
#
# 默认行为（repair mode）：
# 1) 抓取当前网络与 sing-box 状态
# 2) 执行恢复动作（重启 launchd daemon、刷新 DNS cache）
# 3) 默认只校验 Wi-Fi DNS，不强制改写；显式传 --enforce-dns 才会写 DNS
# 4) 尝试恢复重启前的 selector（避免节点回到默认值）
# 5) 再次抓取状态 + 连通性探测
# 6) 输出日志路径，便于后续排障

WIFI_SERVICE="Wi-Fi"
TARGET_DNS="223.5.5.5"
COLLECT_ONLY="false"
ENFORCE_DNS="false"
REPAIR_ONLY="false"
RESTORE_SELECTOR="true"
WAIT_NETWORK_SECONDS="0"
READY_TIMEOUT_SECONDS="30"
CLASH_SECRET=""
PRE_REPAIR_SELECTOR=""
REPAIR_ACTIONS_RUN="false"
LAUNCHD_PLIST="/Library/LaunchDaemons/local.singbox.tun.plist"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --collect-only)
      COLLECT_ONLY="true"
      shift
      ;;
    --repair-only)
      REPAIR_ONLY="true"
      shift
      ;;
    --enforce-dns)
      ENFORCE_DNS="true"
      shift
      ;;
    --no-restore-selector)
      RESTORE_SELECTOR="false"
      shift
      ;;
    --wait-network-seconds)
      WAIT_NETWORK_SECONDS="${2:-}"
      shift 2
      ;;
    --ready-timeout-seconds)
      READY_TIMEOUT_SECONDS="${2:-}"
      shift 2
      ;;
    --dns)
      TARGET_DNS="${2:-}"
      shift 2
      ;;
    --service)
      WIFI_SERVICE="${2:-}"
      shift 2
      ;;
    -h|--help)
      sed -n '1,20p' "$0"
      exit 0
      ;;
    *)
      echo "[ERROR] 未知参数: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$TARGET_DNS" ]]; then
  echo "[ERROR] --dns 不能为空" >&2
  exit 2
fi

if ! [[ "$WAIT_NETWORK_SECONDS" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] --wait-network-seconds 必须是非负整数" >&2
  exit 2
fi

if ! [[ "$READY_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
  echo "[ERROR] --ready-timeout-seconds 必须是正整数" >&2
  exit 2
fi

LOG_DIR="${LOG_DIR:-$HOME/Library/Logs}"
TS="$(date '+%Y%m%d-%H%M%S')"
LOG_FILE="${LOG_DIR}/singbox-netdiag-${TS}.log"
mkdir -p "$LOG_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1

on_error() {
  local rc=$?
  warn "脚本在第 ${BASH_LINENO[0]} 行失败(rc=${rc})，请检查日志: ${LOG_FILE}"
  exit "$rc"
}

trap on_error ERR

info() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

run_allow_fail() {
  local title="$1"
  shift
  local rc=0
  echo
  echo "===== ${title} ====="
  if "$@"; then
    return 0
  else
    rc=$?
  fi
  warn "命令失败(rc=${rc}): $*"
  return 0
}

run_allow_fail_shell() {
  local title="$1"
  local cmd="$2"
  local rc=0
  echo
  echo "===== ${title} ====="
  if bash -lc "$cmd"; then
    return 0
  else
    rc=$?
  fi
  warn "命令失败(rc=${rc}): ${cmd}"
  return 0
}

run_priv_allow_fail() {
  local title="$1"
  shift
  local rc=0
  echo
  echo "===== ${title} ====="

  if "$@"; then
    return 0
  else
    rc=$?
  fi

  warn "普通权限失败(rc=${rc})，尝试 sudo: $*"
  if sudo "$@"; then
    return 0
  fi

  rc=$?
  warn "sudo 也失败(rc=${rc}): $*"
  return 0
}

get_service_device() {
  networksetup -listnetworkserviceorder 2>/dev/null | awk -v target="$WIFI_SERVICE" '
    $0 ~ "\\) " target "$" {
      found=1
      next
    }
    found && match($0, /Device: ([^)]+)/, m) {
      print m[1]
      exit
    }
  '
}

fetch_clash_secret() {
  local rendered="/run/secrets/rendered/singbox-client.json"

  if [[ -n "$CLASH_SECRET" ]]; then
    return 0
  fi

  CLASH_SECRET="$(sudo sed -n 's/.*"secret"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$rendered" 2>/dev/null | head -n1 || true)"
  if [[ -z "$CLASH_SECRET" ]]; then
    warn "未拿到 clash_api secret，跳过 selector 采集/恢复。"
    return 1
  fi

  return 0
}

capture_selector_before_repair() {
  local resp

  if [[ "$RESTORE_SELECTOR" != "true" ]]; then
    info "按参数跳过 selector 采集（--no-restore-selector）"
    return 0
  fi

  if ! fetch_clash_secret; then
    return 0
  fi

  echo
  echo "===== capture selector (before repair) ====="
  resp="$(curl -sS -H "Authorization: Bearer ${CLASH_SECRET}" http://127.0.0.1:9090/proxies/select || true)"
  PRE_REPAIR_SELECTOR="$(printf '%s\n' "$resp" | sed -n 's/.*"now"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"

  if [[ -z "$PRE_REPAIR_SELECTOR" ]]; then
    warn "未从 /proxies/select 提取到当前 selector，后续不执行回写。"
    return 0
  fi

  info "已记录重启前 selector: ${PRE_REPAIR_SELECTOR}"
}

restore_selector_after_repair() {
  local resp verify

  if [[ "$RESTORE_SELECTOR" != "true" ]]; then
    return 0
  fi

  if [[ -z "$PRE_REPAIR_SELECTOR" ]]; then
    warn "没有可恢复的 selector（重启前未采集到）。"
    return 0
  fi

  if ! fetch_clash_secret; then
    return 0
  fi

  echo
  echo "===== restore selector (after repair) ====="
  resp="$(curl -sS -X PUT \
    -H "Authorization: Bearer ${CLASH_SECRET}" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${PRE_REPAIR_SELECTOR}\"}" \
    http://127.0.0.1:9090/proxies/select || true)"
  info "selector 回写请求已发送: ${PRE_REPAIR_SELECTOR}"
  if [[ -n "$resp" ]]; then
    printf '%s\n' "$resp"
  fi

  verify="$(curl -sS -H "Authorization: Bearer ${CLASH_SECRET}" http://127.0.0.1:9090/proxies/select || true)"
  printf '%s\n' "$verify" | sed -n '1,20p'
}

get_current_dns() {
  local output
  output="$(networksetup -getdnsservers "$WIFI_SERVICE" 2>&1 || true)"
  if [[ "$output" == *"There aren't any DNS Servers set"* ]]; then
    echo "empty"
    return 0
  fi

  printf '%s\n' "$output" | awk 'NF {print $1}'
}

dns_contains_target() {
  local current_dns
  current_dns="$(get_current_dns)"
  grep -Fxq "$TARGET_DNS" <<<"$current_dns"
}

report_dns_state() {
  local current_dns
  current_dns="$(get_current_dns)"

  echo
  echo "===== DNS status (${WIFI_SERVICE}) ====="
  if [[ "$current_dns" == "empty" ]]; then
    warn "Wi-Fi DNS 当前为空。macOS 可能回退到 ISP resolver，容易出现 resolver split。"
    return 0
  fi

  printf '%s\n' "$current_dns"
  if dns_contains_target; then
    info "Wi-Fi DNS 已包含目标 DNS: ${TARGET_DNS}"
  else
    warn "Wi-Fi DNS 未包含目标 DNS: ${TARGET_DNS}"
  fi
}

wait_for_launchd_healthy() {
  local attempts=8
  local i=1
  local output=""

  echo
  echo "===== wait for launchd healthy ====="

  while (( i <= attempts )); do
    output="$(launchctl print system/local.singbox.tun 2>&1 || true)"
    if grep -q 'state = running' <<<"$output" && grep -q 'last exit code = 0' <<<"$output"; then
      info "local.singbox.tun 已恢复 healthy（attempt ${i}/${attempts}）"
      printf '%s\n' "$output" | sed -n '1,80p'
      return 0
    fi

    warn "local.singbox.tun 尚未 healthy（attempt ${i}/${attempts}），继续等待"
    sleep 1
    ((i++))
  done

  warn "等待 healthy 超时，输出最近状态供排查"
  printf '%s\n' "$output" | sed -n '1,120p'
  return 1
}

wait_for_network_ready() {
  local wait_seconds="$WAIT_NETWORK_SECONDS"
  local device=""
  local i=1

  if (( wait_seconds <= 0 )); then
    return 0
  fi

  device="$(get_service_device || true)"
  echo
  echo "===== wait for network ready ====="
  info "wake 场景预等待 ${wait_seconds}s，避免在 Wi-Fi/TUN 尚未恢复时过早重启 sing-box"

  while (( i <= wait_seconds )); do
    if [[ -n "$device" ]] && ifconfig "$device" 2>/dev/null | grep -q 'status: active'; then
      info "检测到 ${WIFI_SERVICE} 设备 ${device} 已 active（attempt ${i}/${wait_seconds}）"
      return 0
    fi
    sleep 1
    ((i++))
  done

  warn "在 ${wait_seconds}s 内未确认 ${WIFI_SERVICE} 设备 active，继续执行恢复。"
  return 0
}

wait_for_singbox_runtime_ready() {
  local attempts="$READY_TIMEOUT_SECONDS"
  local i=1
  local output=""
  local configs=""
  local tun_ready="false"
  local api_ready="false"
  local launchd_ready="false"

  echo
  echo "===== wait for sing-box runtime ready ====="

  fetch_clash_secret >/dev/null 2>&1 || true

  while (( i <= attempts )); do
    output="$(launchctl print system/local.singbox.tun 2>&1 || true)"
    launchd_ready="false"
    api_ready="false"
    tun_ready="false"

    if grep -q 'state = running' <<<"$output" && grep -q 'pid = ' <<<"$output"; then
      launchd_ready="true"
    fi

    if grep -q 'sing-box started' /tmp/singbox.log 2>/dev/null \
      && grep -Fq 'inbound/tun[tun-in]: started at' /tmp/singbox.log 2>/dev/null \
      && grep -Fq 'clash-api: restful api listening' /tmp/singbox.log 2>/dev/null; then
      tun_ready="true"
    fi

    if [[ -n "$CLASH_SECRET" ]]; then
      configs="$(curl -fsS --max-time 2 -H "Authorization: Bearer ${CLASH_SECRET}" http://127.0.0.1:9090/configs 2>/dev/null || true)"
      if [[ -n "$configs" ]]; then
        api_ready="true"
      fi
    fi

    if [[ "$launchd_ready" == "true" && "$tun_ready" == "true" && "$api_ready" == "true" ]]; then
      info "sing-box 运行态已就绪（attempt ${i}/${attempts}）"
      printf '%s\n' "$output" | sed -n '1,60p'
      return 0
    fi

    warn "sing-box 尚未完全 ready（attempt ${i}/${attempts}，launchd=${launchd_ready}, tun=${tun_ready}, api=${api_ready}）"
    sleep 1
    ((i++))
  done

  warn "等待 sing-box runtime ready 超时，输出最近状态供排查"
  printf '%s\n' "$output" | sed -n '1,80p'
  run_allow_fail_shell "tail /tmp/singbox.log (recent)" "tail -n 120 /tmp/singbox.log"
  return 1
}

collect_clash_api() {
  echo
  echo "===== clash-api snapshot ====="
  if [[ ! -r "/run/secrets/rendered/singbox-client.json" ]]; then
    warn "当前用户不可读 /run/secrets/rendered/singbox-client.json，尝试 sudo 读取"
  fi

  if ! fetch_clash_secret; then
    warn "跳过 /configs /proxies 采集"
    return 0
  fi

  run_allow_fail_shell "GET /configs" "curl -sS -H 'Authorization: Bearer ${CLASH_SECRET}' http://127.0.0.1:9090/configs"
  run_allow_fail_shell "GET /proxies/select" "curl -sS -H 'Authorization: Bearer ${CLASH_SECRET}' http://127.0.0.1:9090/proxies/select"
  run_allow_fail_shell "GET /proxies/urltest" "curl -sS -H 'Authorization: Bearer ${CLASH_SECRET}' http://127.0.0.1:9090/proxies/urltest"
}

probe_url() {
  local label="$1"
  local url="$2"
  local out_file="$3"

  echo
  echo "===== probe: ${label} (${url}) ====="
  curl -vI --max-time 10 "$url" >"$out_file" 2>&1 || true
  sed -n '1,120p' "$out_file"
}

collect_state() {
  local stage="$1"
  local home_log="$HOME/Library/Logs/sing-box.log"

  echo
  echo "################################################################"
  echo "### STATE SNAPSHOT: ${stage}"
  echo "################################################################"

  run_allow_fail "date" date '+%F %T %z'
  run_allow_fail "whoami" whoami
  run_allow_fail "id" id
  run_allow_fail "uname -a" uname -a
  run_allow_fail "networksetup -getdnsservers ${WIFI_SERVICE}" networksetup -getdnsservers "$WIFI_SERVICE"
  run_allow_fail_shell "scutil --dns (head)" "scutil --dns | sed -n '1,180p'"
  run_allow_fail "launchctl print system/local.singbox.tun" launchctl print system/local.singbox.tun
  run_allow_fail_shell "tail /tmp/singbox.log" "tail -n 180 /tmp/singbox.log"
  run_allow_fail_shell "tail ${home_log}" "tail -n 180 '${home_log}'"
  run_allow_fail_shell "tail rendered config key fields" "sudo grep -n 'default_domain_resolver\\|\"final\"\\s*:\\s*\"remote\"\\|\"tag\"\\s*:\\s*\"remote\"\\|\"server\"\\s*:\\s*\"223.5.5.5\"\\|\"server\"\\s*:\\s*\"1.1.1.1\"' /run/secrets/rendered/singbox-client.json | sed -n '1,120p'"
  collect_clash_api
}

summarize_probe() {
  local probe_file="$1"
  local label="$2"

  if grep -q 'subjectAltName: "chatgpt.com" matches' "$probe_file"; then
    info "${label}: TLS 证书匹配正常"
    return 0
  fi

  if grep -Eq 'SSL: no alternative certificate subject name matches|unexpected eof while reading|TLS connect error' "$probe_file"; then
    warn "${label}: 出现 TLS 异常（可能存在 DNS 分裂/污染或链路异常）"
    return 0
  fi

  warn "${label}: 未命中明确特征，请人工查看完整 probe 输出"
}

CHATGPT_PROBE_FILE="$(mktemp "${TMPDIR:-/tmp}/chatgpt-probe.XXXXXX")"
YOUTUBE_PROBE_FILE="$(mktemp "${TMPDIR:-/tmp}/youtube-probe.XXXXXX")"
trap 'rm -f "$CHATGPT_PROBE_FILE" "$YOUTUBE_PROBE_FILE"' EXIT

info "日志文件: ${LOG_FILE}"
info "参数: WIFI_SERVICE=${WIFI_SERVICE}, TARGET_DNS=${TARGET_DNS}, COLLECT_ONLY=${COLLECT_ONLY}, REPAIR_ONLY=${REPAIR_ONLY}, ENFORCE_DNS=${ENFORCE_DNS}, RESTORE_SELECTOR=${RESTORE_SELECTOR}, WAIT_NETWORK_SECONDS=${WAIT_NETWORK_SECONDS}, READY_TIMEOUT_SECONDS=${READY_TIMEOUT_SECONDS}"

if [[ "$REPAIR_ONLY" != "true" ]]; then
  collect_state "before"
  report_dns_state
fi

capture_selector_before_repair

if [[ "$COLLECT_ONLY" != "true" ]]; then
  REPAIR_ACTIONS_RUN="true"
  echo
  echo "################################################################"
  echo "### REPAIR ACTIONS"
  echo "################################################################"

  wait_for_network_ready

  # 关键动作1：重启 sing-box 的 launchd daemon（system domain）。
  # Why: 根据现场日志，wake 后最常见的根因是 daemon/TUN 运行态失同步，而不是 DNS 配置本身错误。
  run_priv_allow_fail "launchctl kickstart -k system/local.singbox.tun" launchctl kickstart -k system/local.singbox.tun
  if ! wait_for_launchd_healthy || ! wait_for_singbox_runtime_ready; then
    warn "kickstart 后仍未完全恢复，尝试 bootout/bootstrap 重建 launchd job"
    run_priv_allow_fail "launchctl bootout system ${LAUNCHD_PLIST}" launchctl bootout system "${LAUNCHD_PLIST}"
    run_priv_allow_fail "launchctl bootstrap system ${LAUNCHD_PLIST}" launchctl bootstrap system "${LAUNCHD_PLIST}"
    wait_for_launchd_healthy || true
    wait_for_singbox_runtime_ready || true
  fi

  # 关键动作2：刷新 macOS DNS cache（dscache + mDNSResponder）。
  # Why: daemon 恢复后，清理 stale resolver cache，减少 wake 后短时间内的旧解析残留。
  run_priv_allow_fail "dscacheutil -flushcache" dscacheutil -flushcache
  run_priv_allow_fail "killall -HUP mDNSResponder" killall -HUP mDNSResponder

  # 关键动作3：默认不强制改写 Wi-Fi DNS，只做校验。
  # Why: 这次根因更像 runtime issue；DNS 只用于避免 resolver 回退到 ISP DNS。
  if [[ "$ENFORCE_DNS" == "true" ]]; then
    run_priv_allow_fail "set Wi-Fi DNS -> ${TARGET_DNS}" networksetup -setdnsservers "$WIFI_SERVICE" "$TARGET_DNS"
  else
    info "跳过 DNS 改写；如需强制写入 ${TARGET_DNS}，请显式使用 --enforce-dns"
  fi

  run_allow_fail "sleep 3" sleep 3
  restore_selector_after_repair
fi

if [[ "$REPAIR_ONLY" != "true" ]]; then
  echo
  echo "################################################################"
  echo "### CONNECTIVITY PROBES"
  echo "################################################################"
  probe_url "chatgpt" "https://chatgpt.com" "$CHATGPT_PROBE_FILE"
  probe_url "youtube" "https://www.youtube.com" "$YOUTUBE_PROBE_FILE"
  run_allow_fail "nslookup chatgpt.com" nslookup chatgpt.com
  run_allow_fail "nslookup www.youtube.com" nslookup www.youtube.com

  collect_state "after"

  echo
  echo "################################################################"
  echo "### QUICK SUMMARY"
  echo "################################################################"
  run_allow_fail "current DNS (${WIFI_SERVICE})" networksetup -getdnsservers "$WIFI_SERVICE"
  report_dns_state
  summarize_probe "$CHATGPT_PROBE_FILE" "chatgpt probe"
  if grep -Eq 'IPv4: 198\.18\.|IPv6: fc00::' "$CHATGPT_PROBE_FILE"; then
    info "chatgpt probe: 连接目标包含 FakeIP（198.18.0.0/15 或 fc00::/18），符合 TUN 预期。"
  else
    warn "chatgpt probe: 未看到 FakeIP 连接目标，可能发生 resolver split。"
  fi
else
  echo
  echo "################################################################"
  echo "### QUICK SUMMARY (REPAIR ONLY)"
  echo "################################################################"
  run_allow_fail "current DNS (${WIFI_SERVICE})" networksetup -getdnsservers "$WIFI_SERVICE"
  report_dns_state
  if [[ "$REPAIR_ACTIONS_RUN" == "true" ]]; then
    info "repair-only 模式完成：已执行恢复动作且尝试回写 selector。"
  else
    warn "repair-only 模式未执行恢复动作（可能使用了 --collect-only）。"
  fi
fi

echo
info "完成。请把这份日志发给我：${LOG_FILE}"
