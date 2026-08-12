#!/usr/bin/env bash
# Phase 8 续跑：bootstrap 中途中断后的剩余步骤（age key 已手动修正）。
# 跳过已完成（用户/Nix/key），从「增量 rsync → HM switch → sm switch → tailscale → sops → 锁 sshd」续。
set -euo pipefail

HOST="${HOST:-43.156.103.43}"
NODE="${NODE:-sm-vps-tc}"
USERNAME="${USERNAME:-luck}"
FLAKE_SRC="${FLAKE_SRC:-$(pwd)}"
REMOTE_FLAKE="${REMOTE_FLAKE:-/home/${USERNAME}/Desktop/dotfiles}"
HM_REV="${HM_REV:-a1645f407776}"
SM_REV="${SM_REV:-48d47346e0c6}"
HM_BACKUP_EXT="${HM_BACKUP_EXT:-hm.bak}"
UID_LUCK="${UID_LUCK:-1001}"
VERIFY_SECRET="${VERIFY_SECRET:-GITHUB_TOKEN}"
TS_AUTHKEY_FILE="${TS_AUTHKEY_FILE:-}"

log() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
die() { echo "error: $*" >&2; exit 1; }

: "${ROOT_PASS:?set ROOT_PASS}"
command -v sshpass >/dev/null || die "sshpass not found"

RSSH() {
  SSHPASS="${ROOT_PASS}" sshpass -e ssh \
    -o StrictHostKeyChecking=accept-new -o ConnectTimeout=30 -o ServerAliveInterval=15 \
    "root@${HOST}" "$@"
}
LSSH() {
  ssh -o BatchMode=yes -o ConnectTimeout=30 -o ServerAliveInterval=15 -o StrictHostKeyChecking=accept-new \
    "${USERNAME}@${HOST}" "$@"
}

# ---- 增量 rsync（带 keepalive，跨境链路不超时） ----
log "incremental rsync -> ${REMOTE_FLAKE}"
SSHPASS="${ROOT_PASS}" sshpass -e rsync -a --delete \
  -e "ssh -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=15" \
  --exclude='.git' --exclude='.claude' --exclude='.worktrees' \
  --exclude='result' --exclude='results' --exclude='docs' \
  --exclude='.ruff_cache' --exclude='.direnv' \
  --exclude='.apm' --exclude='.tms' \
  "${FLAKE_SRC}/" "root@${HOST}:${REMOTE_FLAKE}/"
RSSH "chown -R ${USERNAME}:${USERNAME} ${REMOTE_FLAKE}"
RSSH "grep -q sm-vps-tc ${REMOTE_FLAKE}/lib/inventory/data.nix && echo flake_has_tc"

# ---- HM switch ----
log "home-manager switch --flake ${REMOTE_FLAKE}#${NODE}"
LSSH "bash -lc '
  set -euo pipefail
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  export HOME=/home/${USERNAME}; export USER=${USERNAME}; export HOME_MANAGER_BACKUP_EXT=${HM_BACKUP_EXT}
  if [[ -S /run/user/${UID_LUCK}/bus ]]; then
    export XDG_RUNTIME_DIR=/run/user/${UID_LUCK}; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${UID_LUCK}/bus
  fi
  cd ${REMOTE_FLAKE}
  nix run github:nix-community/home-manager/${HM_REV} -- switch --flake ${REMOTE_FLAKE}#${NODE} -b ${HM_BACKUP_EXT}
'"

# ---- sm switch ----
log "system-manager switch --flake ${REMOTE_FLAKE}#${NODE}"
LSSH "bash -lc '
  set -euo pipefail
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  export HOME=/home/${USERNAME}
  cd ${REMOTE_FLAKE}
  # sudo 重置 PATH 后 nix 不在其中：用完整二进制路径（multi-user Nix 固定位置）。
  sudo -n /nix/var/nix/profiles/default/bin/nix run github:numtide/system-manager/${SM_REV} -- switch --flake ${REMOTE_FLAKE}#${NODE}
'"

# ---- tailscale ----
log "tailscale install + up"
if RSSH 'command -v tailscale >/dev/null 2>&1'; then
  log "tailscale already installed"
else
  RSSH "bash -lc 'export DEBIAN_FRONTEND=noninteractive; curl -fsSL https://tailscale.com/install.sh | sh'"
fi
if [[ -n ${TS_AUTHKEY_FILE} && -f ${TS_AUTHKEY_FILE} ]]; then
  # 去换行后经 root push 到 luck home，以 luck+sudo 执行 tailscale up。
  SSHPASS="${ROOT_PASS}" sshpass -e scp -o StrictHostKeyChecking=accept-new \
    "${TS_AUTHKEY_FILE}" "root@${HOST}:/tmp/ts-authkey-clean"
  RSSH "tr -d '\n' < /tmp/ts-authkey-clean > /home/${USERNAME}/.ts-authkey && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ts-authkey && chmod 600 /home/${USERNAME}/.ts-authkey && rm -f /tmp/ts-authkey-clean"
  LSSH "sudo -n tailscale up --authkey='file:/home/${USERNAME}/.ts-authkey' && rm -f /home/${USERNAME}/.ts-authkey && tailscale status | head -6"
else
  log "WARN: no TS_AUTHKEY_FILE; 请手动 tailscale up"
fi

# ---- sops 验证 ----
log "verify sops secret ${VERIFY_SECRET}"
LSSH "bash -lc '
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
  export HOME=/home/${USERNAME}
  if [[ -S /run/user/${UID_LUCK}/bus ]]; then
    export XDG_RUNTIME_DIR=/run/user/${UID_LUCK}; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${UID_LUCK}/bus
    systemctl --user start sops-nix.service 2>/dev/null || true
  fi
  sleep 2
  p=\$HOME/.config/sops-nix/secrets/${VERIFY_SECRET}
  if [[ -r \$p && -s \$p ]]; then echo \"sops_ok: ${VERIFY_SECRET} readable\"; else echo \"WARN: ${VERIFY_SECRET} not readable\"; fi
  ls \$HOME/.config/sops-nix/secrets/ 2>/dev/null | head -8
'"

# ---- 锁 sshd ----
log "harden sshd: PermitRootLogin no + PasswordAuthentication no"
RSSH "bash -lc '
  set -euo pipefail
  cat > /etc/ssh/sshd_config.d/99-sm-hardening.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
  sshd -t || { echo sshd_config_invalid; exit 1; }
  systemctl reload ssh || systemctl restart ssh
  echo sshd_hardened
'"
sleep 1
log "verify luck still logs in after hardening"
LSSH 'id' || die "post-hardening luck login failed!"
log "phase8-resume done"
