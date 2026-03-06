#!/usr/bin/env bash
set -euo pipefail

# NetBird latency/relay diagnosis helper
# - Supports local run or remote via SSH
# - Focus: control plane (DNS/FakeIP), data plane (route/latency), NAT (STUN UDP)

usage() {
  cat <<'USAGE'
Usage:
  nb-diag.sh [options]

Options:
  -n, --nb-ip <ip>          NetBird IP of peer (100.x)
  -p, --peer-pub-ip <ip>    Peer public endpoint IP (from netbird status -dA)
  -s, --stun-host <host>    STUN host (default: stun.netbird.io)
  -P, --stun-ports <ports>  STUN UDP ports, comma separated (default: 443,5555)
  -H, --ssh-host <host>     Run on remote host via SSH
  -U, --ssh-user <user>     SSH user (default: current user)
  -S, --ssh-pass <pass>     SSH password (uses sshpass if set)
  -o, --ssh-opts <opts>     Extra SSH options (default: -o StrictHostKeyChecking=no)
  -h, --help                Show this help

Examples:
  ./nb-diag.sh -n 100.71.133.203 -p 203.0.113.10
  ./nb-diag.sh -H 192.168.71.97 -U luck -S 159357 -n 100.71.133.203
USAGE
}

NB_IP=""
PEER_PUB_IP=""
STUN_HOST="stun.netbird.io"
STUN_PORTS="443,5555"
SSH_HOST=""
SSH_USER=""
SSH_PASS=""
SSH_OPTS="-o StrictHostKeyChecking=no"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--nb-ip) NB_IP="$2"; shift 2 ;;
    -p|--peer-pub-ip) PEER_PUB_IP="$2"; shift 2 ;;
    -s|--stun-host) STUN_HOST="$2"; shift 2 ;;
    -P|--stun-ports) STUN_PORTS="$2"; shift 2 ;;
    -H|--ssh-host) SSH_HOST="$2"; shift 2 ;;
    -U|--ssh-user) SSH_USER="$2"; shift 2 ;;
    -S|--ssh-pass) SSH_PASS="$2"; shift 2 ;;
    -o|--ssh-opts) SSH_OPTS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
 done

if [ -n "$SSH_HOST" ] && [ -z "$SSH_USER" ]; then
  SSH_USER="$USER"
fi

run_cmd() {
  local cmd="$1"
  if [ -n "$SSH_HOST" ]; then
    if [ -n "$SSH_PASS" ]; then
      if ! command -v sshpass >/dev/null 2>&1; then
        echo "[ERROR] sshpass not found, but --ssh-pass was provided." >&2
        exit 1
      fi
      sshpass -p "$SSH_PASS" ssh $SSH_OPTS "${SSH_USER}@${SSH_HOST}" "$cmd"
    else
      ssh $SSH_OPTS "${SSH_USER}@${SSH_HOST}" "$cmd"
    fi
  else
    bash -lc "$cmd"
  fi
}

section() {
  echo
  echo "## $1"
}

section "snapshot"
run_cmd "date"
run_cmd "uname -a || true"

section "netbird status"
run_cmd "command -v netbird >/dev/null 2>&1 && netbird status -dA || echo 'netbird not found'"

section "dns check (control plane)"
# 关键域名：api/signal/relay.netbird.io
# 如果解析到 FakeIP (198.18.0.0/15 或 fc00::/7)，需要绕过 FakeIP 或确保路由进 TUN
run_cmd "command -v dig >/dev/null 2>&1 && (dig +short api.netbird.io; dig +short signal.netbird.io; dig +short relay.netbird.io) || echo 'dig not found'"

section "fakeip routes (linux only)"
# FakeIP 段必须指向 TUN，否则会走默认网关导致超时
run_cmd "command -v ip >/dev/null 2>&1 && (ip route | grep -E '198\\.18\\.' || true; ip -6 route | grep -E '^fc00:' || true) || echo 'ip not found (skip)'
"

section "route to peer public ip"
if [ -n "$PEER_PUB_IP" ]; then
  # 重点看出接口是否是 TUN/utun
  run_cmd "(command -v ip >/dev/null 2>&1 && ip route get $PEER_PUB_IP) || (command -v route >/dev/null 2>&1 && route -n get $PEER_PUB_IP) || echo 'route/ip not found'"
else
  echo "PEER_PUB_IP not set (skip)"
fi

section "ping netbird ip"
if [ -n "$NB_IP" ]; then
  # COUNT/INTERVAL 为快速诊断值
  run_cmd "ping -c 10 -i 0.2 $NB_IP || true"
else
  echo "NB_IP not set (skip)"
fi

section "ping peer public ip"
if [ -n "$PEER_PUB_IP" ]; then
  run_cmd "ping -c 10 -i 0.2 $PEER_PUB_IP || true"
else
  echo "PEER_PUB_IP not set (skip)"
fi

section "mtr (if available)"
# macOS 需要 brew install mtr
if [ -n "$NB_IP" ]; then
  run_cmd "command -v mtr >/dev/null 2>&1 && mtr -rwzc 50 $NB_IP || echo 'mtr not found'"
else
  echo "NB_IP not set (skip)"
fi

section "stun udp check"
# NAT/打洞能力核心检查：UDP 到 STUN 是否可达
PORTS=$(echo "$STUN_PORTS" | tr ',' ' ')
run_cmd "command -v nc >/dev/null 2>&1 && for p in $PORTS; do nc -u -z -w2 $STUN_HOST \$p >/dev/null 2>&1 && echo OK $STUN_HOST:\$p || echo FAIL $STUN_HOST:\$p; done || echo 'nc not found'"

section "netbird netcheck"
# netbird netcheck 会显示 NAT 类型/UDP 能力/DERP
run_cmd "command -v netbird >/dev/null 2>&1 && netbird netcheck || echo 'netbird not found or netcheck unsupported'"

section "notes"
cat <<'NOTES'
- 如果 Connection type 是 P2P 但 RTT 高，重点看“route to peer public ip”是否被 TUN 接走。
- 如果 Signal/Relays 断开，优先检查 DNS 是否被 FakeIP 劫持。
- 如果 STUN UDP FAIL，多半是 NAT/防火墙限制，容易回退 relay。
NOTES
