#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/infra/scripts/k3s-residue-cleanup.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

FAKE_BIN="${TMP_DIR}/bin"
mkdir -p "${FAKE_BIN}"

cat > "${FAKE_BIN}/ps" <<'EOF'
#!/usr/bin/env bash
cat <<'OUT'
  PID  PPID   UID CMD
27200 27054 65532 traefik traefik --entryPoints.web.address=:8000/tcp --entryPoints.websecure.address=:8443/tcp
27054     1     0 /nix/store/k3s/bin/containerd-shim-runc-v2 -namespace k8s.io -id deadbeef
93034 69006     0 /nix/store/moby/libexec/docker/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 443
OUT
EOF

cat > "${FAKE_BIN}/readlink" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-f" && "${2:-}" == "/proc/27200/exe" ]]; then
  printf '%s\n' "/nix/store/traefik/bin/traefik"
  exit 0
fi
if [[ "${1:-}" == "-f" && "${2:-}" == "/proc/27054/exe" ]]; then
  printf '%s\n' "/nix/store/k3s/bin/containerd-shim-runc-v2"
  exit 0
fi
exit 1
EOF

cat > "${FAKE_BIN}/cat" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "/proc/27200/cgroup" ]]; then
  printf '%s\n' '0::/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-pod06010.scope/cri-containerd-traefik.scope'
  exit 0
fi
if [[ "${1:-}" == "/proc/27054/cgroup" ]]; then
  printf '%s\n' '0::/system.slice/fake.scope'
  exit 0
fi
/bin/cat "$@"
EOF

cat > "${FAKE_BIN}/kill" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${KILL_LOG}"
EOF

cat > "${FAKE_BIN}/iptables" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-t" && "${2:-}" == "nat" && "${3:-}" == "-S" && "${4:-}" == "KUBE-SERVICES" ]]; then
  cat <<'OUT'
-A KUBE-SERVICES -d 142.171.154.61/32 -p tcp -m comment --comment "networking/traefik:web external IP" -m tcp --dport 80 -j KUBE-EXT-FCOZJUKMQRACOVLH
-A KUBE-SERVICES -d 142.171.154.61/32 -p tcp -m comment --comment "networking/traefik:websecure external IP" -m tcp --dport 443 -j KUBE-EXT-WX5JHK7DACYWTMQQ
OUT
  exit 0
fi

printf '%s\n' "$*" >> "${IPTABLES_LOG}"
EOF

chmod +x "${FAKE_BIN}/ps" "${FAKE_BIN}/readlink" "${FAKE_BIN}/cat" "${FAKE_BIN}/kill" "${FAKE_BIN}/iptables"

export PATH="${FAKE_BIN}:${PATH}"
export KILL_LOG="${TMP_DIR}/kill.log"
export IPTABLES_LOG="${TMP_DIR}/iptables.log"
export KILL_BIN="${FAKE_BIN}/kill"
export K3S_CLEANUP_SKIP_ROOT_CHECK=1
export K3S_CLEANUP_ASSUME_TARGETS_LIVE=1

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    printf 'expected output to contain: %s\nactual:\n%s\n' "${needle}" "${haystack}" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "${haystack}" == *"${needle}"* ]]; then
    printf 'expected output NOT to contain: %s\nactual:\n%s\n' "${needle}" "${haystack}" >&2
    exit 1
  fi
}

inspect_output="$("${SCRIPT_PATH}" inspect)"
assert_contains "${inspect_output}" 'TARGET pid=27200'
assert_contains "${inspect_output}" 'TARGET pid=27054'
assert_not_contains "${inspect_output}" 'pid=93034'

"${SCRIPT_PATH}" --apply >/dev/null

kill_output="$(cat "${KILL_LOG}")"
assert_contains "${kill_output}" '-TERM 27200 27054'
assert_contains "${kill_output}" '-KILL 27200 27054'

iptables_output="$(cat "${IPTABLES_LOG}")"
assert_contains "${iptables_output}" '-t nat -D KUBE-SERVICES -d 142.171.154.61/32 -p tcp -m comment --comment networking/traefik:web external IP -m tcp --dport 80 -j KUBE-EXT-FCOZJUKMQRACOVLH'
assert_contains "${iptables_output}" '-t nat -D KUBE-SERVICES -d 142.171.154.61/32 -p tcp -m comment --comment networking/traefik:websecure external IP -m tcp --dport 443 -j KUBE-EXT-WX5JHK7DACYWTMQQ'

printf 'ok\n'
