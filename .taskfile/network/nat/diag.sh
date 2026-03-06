#!/usr/bin/env bash
set -euo pipefail

# NAT diagnose script (read-only by default)
#
# Important vars:
#   OUT:       output log path (default: /tmp/nat-diag-<ts>.log)
#   LAN_CIDR:  LAN subnet to scan (e.g. 192.168.71.0/24)
#   PORT:      service port to check/listen (default: 18888)
#   PUB_IP:    public IP to verify from external network
#   CAPTURE:   enable tcpdump capture (0/1, default: 0) - requires sudo/root
#   IFACE:     capture interface (e.g. enp0s20f0u1)
#   OEA_IP:    target device IP for SSDP/UPnP capture

OUT_DEFAULT="/tmp/nat-diag-$(date +%Y%m%d-%H%M%S).log"
OUT="${OUT:-$OUT_DEFAULT}"
LAN_CIDR="${LAN_CIDR:-}"
PORT="${PORT:-18888}"
PUB_IP="${PUB_IP:-}"
CAPTURE="${CAPTURE:-0}"
IFACE="${IFACE:-}"
OEA_IP="${OEA_IP:-}"

log() {
  printf '%s\n' "$*" | tee -a "$OUT"
}

run() {
  local cmd="$*"
  log "\n$ $cmd"
  bash -c "$cmd" 2>&1 | tee -a "$OUT"
}

has() { command -v "$1" >/dev/null 2>&1; }

log "## NAT diagnose (read-only)"
log "ts=$(date)"
log "host=$(hostname 2>/dev/null || true)"
log "out=$OUT"

log "\n## system"
run "uname -a || true"

log "\n## interfaces / routes"
if has ip; then
  run "ip addr show"
  run "ip route show"
  run "ip -6 route show || true"
  run "ip route get 1.1.1.1 || true"
else
  run "ifconfig -a || true"
  run "netstat -rn || true"
  run "route -n get default || true"
fi

log "\n## public ip"
if has curl; then
  run "curl -4 ifconfig.me || true"
  run "curl -6 ifconfig.me || true"
else
  log "curl not found"
fi

log "\n## IGD / UPnP discovery"
if has upnpc; then
  run "upnpc -l || true"
elif has nix; then
  # Use nix run for miniupnpc when upnpc is not installed.
  run "nix run nixpkgs#miniupnpc -- -l || true"
else
  log "upnpc not found and nix not available"
fi

log "\n## ARP / neighbor table"
if has ip; then
  run "ip neigh show || true"
else
  run "arp -a || true"
fi

log "\n## listen ports (TCP/UDP)"
if has ss; then
  run "ss -lntuap | grep -E '(:|\b)${PORT}(\b|/)' || true"
else
  log "ss not found"
fi

log "\n## LAN scan (optional)"
if [ -n "$LAN_CIDR" ]; then
  if has nmap; then
    # ICMP/ARP discovery for LAN devices (read-only).
    run "nmap -sn $LAN_CIDR"
  else
    log "nmap not found"
  fi
else
  log "LAN_CIDR not set; skip scan"
fi

log "\n## external verification (manual from 4G/VPS)"
if [ -n "$PUB_IP" ]; then
  log "TCP: nc -vz $PUB_IP $PORT"
  log "UDP: nmap -sU -p $PORT $PUB_IP"
else
  log "PUB_IP not set; skip external commands"
fi

log "\n## optional capture (SSDP/UPnP)"
if [ "$CAPTURE" = "1" ]; then
  if ! has tcpdump; then
    log "tcpdump not found"
  elif [ -z "$IFACE" ]; then
    log "IFACE not set (e.g. IFACE=enp0s20f0u1)"
  else
    # SSDP M-SEARCH capture on UDP 1900 (UPnP discovery).
    if [ -n "$OEA_IP" ]; then
      run "sudo tcpdump -i $IFACE host $OEA_IP and udp port 1900 -nn -vv -c 30"
    else
      run "sudo tcpdump -i $IFACE udp port 1900 -nn -vv -c 30"
    fi
  fi
else
  log "CAPTURE=0; skip tcpdump"
fi

log "\n## done"
log "log=$OUT"
