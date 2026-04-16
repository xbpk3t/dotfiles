#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  k3s-residue-cleanup.sh inspect
  k3s-residue-cleanup.sh --apply

Default mode is inspect.

What it does:
  - Detects likely k3s residual processes on a host.
  - Targets only k3s/containerd shim processes and Traefik pods running under k3s.
  - Does not touch Docker containers or delete any data directories.
EOF
}

log() {
  printf '[k3s-cleanup] %s\n' "$*"
}

run_kill() {
  local signal="$1"
  shift

  if [[ -n "${KILL_BIN:-}" ]]; then
    "${KILL_BIN}" "${signal}" "$@"
    return
  fi

  kill "${signal}" "$@"
}

run_iptables() {
  local bin="${IPTABLES_BIN:-iptables}"
  "${bin}" "$@"
}

MODE="inspect"
if [[ $# -gt 1 ]]; then
  usage >&2
  exit 1
fi

if [[ $# -eq 1 ]]; then
  case "$1" in
    inspect)
      MODE="inspect"
      ;;
    --apply)
      MODE="apply"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
fi

if [[ "${MODE}" == "apply" && "${EUID}" -ne 0 && "${K3S_CLEANUP_SKIP_ROOT_CHECK:-0}" != "1" ]]; then
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    exec sudo "$0" --apply
  fi

  log "apply mode requires root privileges"
  exit 1
fi

declare -A PROC_CMD=()
declare -A TARGET_REASON=()
declare -a TARGET_PIDS=()

while read -r pid ppid uid cmd; do
  [[ -n "${pid}" ]] || continue
  PROC_CMD["${pid}"]="${cmd}"
done < <(ps -eo pid=,ppid=,uid=,args=)

is_target_trailing_traefik() {
  local pid="$1"
  local ppid="$2"
  local cgroup exe parent_cmd

  cgroup="$(cat "/proc/${pid}/cgroup" 2>/dev/null || true)"
  exe="$(readlink -f "/proc/${pid}/exe" 2>/dev/null || true)"
  parent_cmd="${PROC_CMD["${ppid}"]:-}"

  [[ "${exe}" == *traefik* ]] || [[ "${cgroup}" == *kubepods* ]] || [[ "${parent_cmd}" == *containerd-shim-runc-v2* ]]
}

discover_targets() {
  local pid ppid uid cmd

  while read -r pid ppid uid cmd; do
    [[ -n "${pid}" ]] || continue

    if [[ "${cmd}" == *containerd-shim-runc-v2* ]] && { [[ "${cmd}" == *" -namespace k8s.io "* ]] || [[ "${cmd}" == *"/run/k3s/containerd/containerd.sock"* ]] || [[ "${cmd}" == *"/var/lib/rancher/k3s/"* ]]; }; then
      TARGET_REASON["${pid}"]="k3s-containerd-shim"
      TARGET_PIDS+=("${pid}")
      continue
    fi

    if [[ "${cmd}" == traefik\ * ]] && is_target_trailing_traefik "${pid}" "${ppid}"; then
      TARGET_REASON["${pid}"]="k3s-traefik-pod"
      TARGET_PIDS+=("${pid}")
      continue
    fi

    if [[ "${cmd}" == *"/bin/k3s"* ]] || [[ "${cmd}" == k3s\ * ]] || [[ "${cmd}" == kubelet\ * && "${cmd}" == *"/var/lib/rancher/k3s"* ]]; then
      TARGET_REASON["${pid}"]="k3s-runtime"
      TARGET_PIDS+=("${pid}")
    fi
  done < <(ps -eo pid=,ppid=,uid=,args=)
}

print_targets() {
  local pid

  if [[ "${#TARGET_PIDS[@]}" -eq 0 ]]; then
    log "no k3s residual processes detected"
    return
  fi

  for pid in "${TARGET_PIDS[@]}"; do
    printf 'TARGET pid=%s reason=%s cmd=%s\n' \
      "${pid}" \
      "${TARGET_REASON["${pid}"]}" \
      "${PROC_CMD["${pid}"]}"
  done
}

port_snapshot() {
  if ! command -v ss >/dev/null 2>&1; then
    return
  fi

  log "port snapshot"
  ss -tulpn 2>/dev/null | grep -E '(:80 |:443 |:4000 |:8000 |:8443 |:6443 )' || true
}

cleanup_stale_kube_external_ip_rules() {
  local rule delete_rule
  local -a rules=()

  if ! command -v "${IPTABLES_BIN:-iptables}" >/dev/null 2>&1; then
    return
  fi

  while IFS= read -r rule; do
    [[ -n "${rule}" ]] || continue
    rules+=("${rule}")
  done < <(run_iptables -t nat -S KUBE-SERVICES 2>/dev/null | grep -E 'external IP' | grep -E -- '--dport (80|443)( |$)' || true)

  if [[ "${#rules[@]}" -eq 0 ]]; then
    return
  fi

  for rule in "${rules[@]}"; do
    delete_rule="${rule/-A /-D }"
    log "deleting stale kube nat rule: ${delete_rule}"
    eval "run_iptables -t nat ${delete_rule}"
  done
}

pid_is_alive() {
  local pid="$1"

  if [[ "${K3S_CLEANUP_ASSUME_TARGETS_LIVE:-0}" == "1" ]]; then
    return 0
  fi

  if [[ -n "${KILL_BIN:-}" ]]; then
    "${KILL_BIN}" -0 "${pid}" >/dev/null 2>&1
    return
  fi

  kill -0 "${pid}" 2>/dev/null
}

apply_targets() {
  local pid existing=()

  for pid in "${TARGET_PIDS[@]}"; do
    if pid_is_alive "${pid}"; then
      existing+=("${pid}")
    fi
  done

  if [[ "${#existing[@]}" -eq 0 ]]; then
    log "no live target processes to stop"
    return
  fi

  log "sending TERM to: ${existing[*]}"
  run_kill -TERM "${existing[@]}"
  sleep 2

  local stubborn=()
  for pid in "${existing[@]}"; do
    if pid_is_alive "${pid}"; then
      stubborn+=("${pid}")
    fi
  done

  if [[ "${#stubborn[@]}" -gt 0 ]]; then
    log "sending KILL to: ${stubborn[*]}"
    run_kill -KILL "${stubborn[@]}"
  fi
}

discover_targets
print_targets
port_snapshot

if [[ "${MODE}" == "apply" ]]; then
  apply_targets
  cleanup_stale_kube_external_ip_rules
  port_snapshot
fi
