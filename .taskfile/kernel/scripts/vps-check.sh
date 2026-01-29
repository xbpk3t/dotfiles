#!/usr/bin/env bash
set -Eeuo pipefail

# -----------------------------
# vps-check.sh
# Full VPS health check:
#   1) ecs (hardware + network + ip/unlock/email)
#   2) NetQuality (deep network)
#   3) IPQuality (deep ip quality/unlock/mail/blacklist)
#
# ecs 的安装/运行命令来自 ecs README 的一键命令与参数（noninteractive=true、-menu=false、-upload=false 等）。
#
# NetQuality 参数来自 NetQuality 的说明（Net.Check.Place、-j、-o、-P/-L/-S/-n/-y/-l 等）。
#
# IPQuality 参数来自 IPQuality README（IP.Check.Place、-E*、-Ej、-o、-En/-Ey 等）。
# -----------------------------

SCRIPT_VERSION="0.1.0"

# Defaults
MODE="full"             # full | quick
LANG="zh"               # ecs language: zh|en
NET_LANG="cn"           # NetQuality language: cn|en
IP_LANG=""              # IPQuality language: empty = default (usually CN); or "en" etc.
OUT_BASE=""             # if empty: auto choose
SKIP_ECS="false"
SKIP_NET="false"
SKIP_IP="false"
NO_DEPS="false"         # if true: pass -n/-En to skip deps detection/install when supported
AUTO_DEPS="true"        # if true: pass -y/-Ey to auto install deps when supported
TIMEOUT_SECS="3600"     # per-tool hard timeout
CONNECT_TIMEOUT="10"    # curl/wget connect timeout
MAX_TIME="60"           # curl/wget per download max time
ECS_INSTALL_FLAVOR="short" # short|raw|cdn|cnb
ECS_ARGS_EXTRA=()
NET_ARGS_EXTRA=()
IP_ARGS_EXTRA=()

# ---- utils ----
ts() { date +"%Y-%m-%d %H:%M:%S"; }
log() { echo "[$(ts)] $*"; }
warn() { echo "[$(ts)] WARN: $*" >&2; }
err() { echo "[$(ts)] ERROR: $*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

need_bash() {
  if [[ -z "${BASH_VERSION:-}" ]]; then
    err "This script requires bash."
    exit 1
  fi
}

as_root_prefix() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo ""
    return
  fi
  if have sudo; then
    # -n: non-interactive; will fail fast if no sudo rights
    if sudo -n true >/dev/null 2>&1; then
      echo "sudo -n"
      return
    fi
  fi
  echo ""
}

download() {
  # download <url> <dest>
  local url="$1" dest="$2"
  if have curl; then
    curl -fsSL --connect-timeout "${CONNECT_TIMEOUT}" --max-time "${MAX_TIME}" "$url" -o "$dest"
    return
  fi
  if have wget; then
    wget -qO "$dest" --timeout="${MAX_TIME}" "$url"
    return
  fi
  err "Neither curl nor wget found. Please install one of them."
  exit 1
}

run_with_timeout() {
  # run_with_timeout <seconds> <cmd...>
  local t="$1"; shift
  if have timeout; then
    timeout --preserve-status "${t}" "$@"
  else
    # No timeout binary; run directly
    "$@"
  fi
}

# ---- output dir ----
pick_out_base() {
  if [[ -n "$OUT_BASE" ]]; then
    echo "$OUT_BASE"
    return
  fi
  # prefer /root if writable, else cwd
  if [[ -w "/root" ]]; then
    echo "/root/vps-check"
  else
    echo "$(pwd)/vps-check"
  fi
}

init_report_dir() {
  local base
  base="$(pick_out_base)"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  REPORT_DIR="${base}/${stamp}"
  mkdir -p "$REPORT_DIR"
  mkdir -p "$REPORT_DIR/artifacts"
  mkdir -p "$REPORT_DIR/logs"
  echo "$REPORT_DIR"
}

# ---- CLI ----
usage() {
  cat <<'EOF'
Usage:
  ./vps-check.sh [options]

Options:
  --full                 Full checks (default)
  --quick                Faster checks (uses NetQuality latency+low-data; still runs all 3)
  --out <dir>            Output base directory (default: /root/vps-check or ./vps-check)
  --timeout <secs>       Per-tool timeout (default: 3600)

  --skip-ecs             Skip ecs
  --skip-net             Skip NetQuality
  --skip-ip              Skip IPQuality

  --no-deps              Tell NetQuality/IPQuality to skip deps checking/install (-n / -En)
  --auto-deps            Tell NetQuality/IPQuality to auto-install deps (-y / -Ey) (default)

  --ecs-lang <zh|en>     ecs language (default: zh)
  --net-lang <cn|en>     NetQuality language (default: cn)
  --ip-lang <xx>         IPQuality language (e.g. en). Empty = default.

  --ecs-install <short|raw|cdn|cnb>
                         ecs installer source (default: short)

  --ecs-args "<...>"     Extra args passed to goecs (example: "--ecs-args '-speed=false -diskm dd'")
  --net-args "<...>"     Extra args passed to NetQuality
  --ip-args "<...>"      Extra args passed to IPQuality

Examples:
  # Full
  ./vps-check.sh

  # Quick (NetQuality latency + low-data)
  ./vps-check.sh --quick

  # Put reports to current folder
  ./vps-check.sh --out ./.reports

  # Skip deps install (useful on locked-down boxes)
  ./vps-check.sh --no-deps

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full) MODE="full"; shift ;;
      --quick) MODE="quick"; shift ;;
      --out) OUT_BASE="${2:-}"; shift 2 ;;
      --timeout) TIMEOUT_SECS="${2:-}"; shift 2 ;;

      --skip-ecs) SKIP_ECS="true"; shift ;;
      --skip-net) SKIP_NET="true"; shift ;;
      --skip-ip)  SKIP_IP="true"; shift ;;

      --no-deps) NO_DEPS="true"; AUTO_DEPS="false"; shift ;;
      --auto-deps) AUTO_DEPS="true"; NO_DEPS="false"; shift ;;

      --ecs-lang) LANG="${2:-}"; shift 2 ;;
      --net-lang) NET_LANG="${2:-}"; shift 2 ;;
      --ip-lang) IP_LANG="${2:-}"; shift 2 ;;

      --ecs-install) ECS_INSTALL_FLAVOR="${2:-}"; shift 2 ;;

      --ecs-args)
        # split by shell words (user provides quotes)
        read -r -a ECS_ARGS_EXTRA <<< "${2:-}"
        shift 2 ;;
      --net-args)
        read -r -a NET_ARGS_EXTRA <<< "${2:-}"
        shift 2 ;;
      --ip-args)
        read -r -a IP_ARGS_EXTRA <<< "${2:-}"
        shift 2 ;;

      -h|--help) usage; exit 0 ;;
      *) err "Unknown arg: $1"; usage; exit 1 ;;
    esac
  done
}

# ---- tool runners ----
ecs_install_cmd() {
  # ecs README lists multiple one-click commands (raw/cdn/cnb/short).:contentReference[oaicite:3]{index=3}
  case "$ECS_INSTALL_FLAVOR" in
    raw)
      echo 'curl -L https://raw.githubusercontent.com/oneclickvirt/ecs/master/goecs.sh -o goecs.sh'
      ;;
    cdn)
      echo 'curl -L https://cdn.spiritlhl.net/https://raw.githubusercontent.com/oneclickvirt/ecs/master/goecs.sh -o goecs.sh'
      ;;
    cnb)
      echo 'curl -L https://cnb.cool/oneclickvirt/ecs/-/git/raw/main/goecs.sh -o goecs.sh'
      ;;
    short|*)
      echo 'curl -L https://bash.spiritlhl.net/goecs -o goecs.sh'
      ;;
  esac
}

run_ecs() {
  local out_txt="$REPORT_DIR/ecs.txt"
  local out_log="$REPORT_DIR/logs/ecs.log"

  log "==> [ecs] install + run (output: $out_txt)"
  (
    set -e
    export noninteractive=true

    # Install goecs via official one-click method.:contentReference[oaicite:4]{index=4}
    local dlcmd
    dlcmd="$(ecs_install_cmd)"

    # Use curl/wget already checked by download(), but here keep it as per official commands.
    bash -lc "$dlcmd"
    chmod +x ./goecs.sh
    ./goecs.sh install

    # Run: disable menu, disable upload (privacy), set language.
    # goecs supports -menu=false -upload=false -l zh/en.:contentReference[oaicite:5]{index=5}
    run_with_timeout "$TIMEOUT_SECS" goecs -menu=false -upload=false -l "$LANG" "${ECS_ARGS_EXTRA[@]}"
  ) > >(tee "$out_txt") 2> >(tee "$out_log" >&2) || return 1

  return 0
}

run_netquality() {
  local out_txt="$REPORT_DIR/netquality.txt"
  local out_json="$REPORT_DIR/netquality.json"
  local out_log="$REPORT_DIR/logs/netquality.log"

  # Base args per docs: language -l cn|en, json -j, output -o, deps control -n/-y, quick flags -P/-L etc.:contentReference[oaicite:6]{index=6}
  local args_txt=()
  local args_json=()

  # deps
  if [[ "$NO_DEPS" == "true" ]]; then
    args_txt+=("-n")
    args_json+=("-n")
  elif [[ "$AUTO_DEPS" == "true" ]]; then
    args_txt+=("-y")
    args_json+=("-y")
  fi

  # language
  args_txt+=("-l" "$NET_LANG")
  args_json+=("-l" "$NET_LANG")

  # quick mode: latency mode + low data mode.:contentReference[oaicite:7]{index=7}
  if [[ "$MODE" == "quick" ]]; then
    args_txt+=("-P" "-L")
    args_json+=("-P" "-L")
  fi

  # extra args from user
  args_txt+=("${NET_ARGS_EXTRA[@]}")
  args_json+=("${NET_ARGS_EXTRA[@]}")

  log "==> [NetQuality] run (text: $out_txt, json: $out_json)"
  (
    set -e
    # 1) human-readable
    run_with_timeout "$TIMEOUT_SECS" bash <(curl -Ls Net.Check.Place) "${args_txt[@]}"
  ) > >(tee "$out_txt") 2> >(tee "$out_log" >&2) || true

  (
    set -e
    # 2) json output to file: -j and -o /path/to/file.json :contentReference[oaicite:8]{index=8}
    run_with_timeout "$TIMEOUT_SECS" bash <(curl -Ls Net.Check.Place) -j -o "$out_json" "${args_json[@]}"
  ) >>"$out_log" 2>&1 || true

  return 0
}

run_ipquality() {
  local out_txt="$REPORT_DIR/ipquality.txt"
  local out_json="$REPORT_DIR/ipquality.json"
  local out_log="$REPORT_DIR/logs/ipquality.log"

  # IPQuality advanced mode uses -E (and variants -E4/-E6 etc), deps: -En / -Ey, json: -Ej, output: -o ... :contentReference[oaicite:9]{index=9}
  local args_txt=("-E")
  local args_json=("-Ej")

  # deps
  if [[ "$NO_DEPS" == "true" ]]; then
    args_txt+=("-En")
    args_json+=("-En")
  elif [[ "$AUTO_DEPS" == "true" ]]; then
    args_txt+=("-Ey")
    args_json+=("-Ey")
  fi

  # language (optional)
  if [[ -n "$IP_LANG" ]]; then
    args_txt+=("-l" "$IP_LANG")
    # -Ej already includes -E semantics for json path in docs; keep -l too
    args_json+=("-l" "$IP_LANG")
  fi

  # quick mode: nothing official like -P/-L for IPQuality; keep same.

  # extra args from user
  args_txt+=("${IP_ARGS_EXTRA[@]}")
  args_json+=("${IP_ARGS_EXTRA[@]}")

  log "==> [IPQuality] run (text: $out_txt, json: $out_json)"
  (
    set -e
    run_with_timeout "$TIMEOUT_SECS" bash <(curl -Ls https://IP.Check.Place) "${args_txt[@]}"
  ) > >(tee "$out_txt") 2> >(tee "$out_log" >&2) || true

  (
    set -e
    # JSON output to file with -o /path/to/file.json :contentReference[oaicite:10]{index=10}
    run_with_timeout "$TIMEOUT_SECS" bash <(curl -Ls https://IP.Check.Place) "${args_json[@]}" -o "$out_json"
  ) >>"$out_log" 2>&1 || true

  return 0
}

write_summary() {
  local f="$REPORT_DIR/summary.txt"
  {
    echo "vps-check summary"
    echo "  script_version: $SCRIPT_VERSION"
    echo "  mode: $MODE"
    echo "  report_dir: $REPORT_DIR"
    echo "  time: $(date -Is)"
    echo
    echo "Files:"
    [[ -f "$REPORT_DIR/ecs.txt" ]] && echo "  - ecs.txt"
    [[ -f "$REPORT_DIR/netquality.txt" ]] && echo "  - netquality.txt"
    [[ -f "$REPORT_DIR/netquality.json" ]] && echo "  - netquality.json"
    [[ -f "$REPORT_DIR/ipquality.txt" ]] && echo "  - ipquality.txt"
    [[ -f "$REPORT_DIR/ipquality.json" ]] && echo "  - ipquality.json"
    echo
    echo "Logs: $REPORT_DIR/logs/"
    echo
    echo "Notes:"
    echo "  - NetQuality docs: bash <(curl -Ls Net.Check.Place) ... (supports -j/-o/-P/-L/-S/-n/-y/-l)"
    echo "  - IPQuality docs:  bash <(curl -Ls https://IP.Check.Place) -E... (supports -Ej and -o file.json)"
  } > "$f"
}

main() {
  need_bash
  parse_args "$@"

  REPORT_DIR="$(init_report_dir)"
  log "Report dir: $REPORT_DIR"

  local failed=0

  if [[ "$SKIP_ECS" != "true" ]]; then
    run_ecs || { warn "ecs failed (see logs/ecs.log)"; failed=1; }
  else
    log "==> [ecs] skipped"
  fi

  if [[ "$SKIP_NET" != "true" ]]; then
    run_netquality || { warn "NetQuality failed (see logs/netquality.log)"; failed=1; }
  else
    log "==> [NetQuality] skipped"
  fi

  if [[ "$SKIP_IP" != "true" ]]; then
    run_ipquality || { warn "IPQuality failed (see logs/ipquality.log)"; failed=1; }
  else
    log "==> [IPQuality] skipped"
  fi

  write_summary

  echo
  log "✅ Done. Open: $REPORT_DIR"
  log "   Summary: $REPORT_DIR/summary.txt"
  [[ "$failed" -eq 0 ]] || warn "Some steps failed. Check logs in $REPORT_DIR/logs/"
}

main "$@"
