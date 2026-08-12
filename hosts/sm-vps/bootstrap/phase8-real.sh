#!/usr/bin/env bash
# Phase 8: 真机 bootstrap（SSH 直连，非 Incus）。
# 目标：从「root + 密码」的裸 Debian/Ubuntu VPS，收敛为
#   luck 用户（SSH key）→ Determinate Nix → standalone HM → system-manager → tailscale → sops。
#
# 用法（在 Mac / 任意有 flake 的机器）：
#   ROOT_PASS='<初始 root 密码>' ./hosts/sm-vps/bootstrap/phase8-real.sh
#   ROOT_PASS='...' HOST=1.2.3.4 NODE=sm-vps-tc ./hosts/sm-vps/bootstrap/phase8-real.sh
#
# 安全顺序（决策 4A）：
#   1. 建 luck + push Mac pubkey
#   2. 验证 luck+key 能登录（BatchMode 非交互）
#   3. 才锁 sshd（PermitRootLogin no + PasswordAuthentication no）
#   保证不会把自己锁在门外。
#
# 幂等：已完成的步骤跳过；可重复执行。
set -euo pipefail

# ---- 参数（默认值） ----
HOST="${HOST:-43.156.103.43}"
NODE="${NODE:-sm-vps-tc}"
USERNAME="${USERNAME:-luck}"
# flake 源码：默认当前目录（仓库根）。rsync 到目标机 /home/luck/Desktop/dotfiles。
FLAKE_SRC="${FLAKE_SRC:-$(pwd)}"
REMOTE_FLAKE="${REMOTE_FLAKE:-/home/${USERNAME}/Desktop/dotfiles}"
# 本机 pubkey / age key
PUBKEY="${PUBKEY:-$HOME/.ssh/id_ed25519.pub}"
# age 私钥：默认 Darwin 的 sops 路径（公钥 = age10prwj4… = secrets.yaml 接收方）。
# 注意：不要用 ~/.config/sops/age/keys.txt——那把公钥是 age1atysh…，解不开 secrets.yaml。
AGE_KEY="${AGE_KEY:-$HOME/Library/Application Support/sops/age/keys.txt}"
# tailscale auth key 文件（root 一次性，用完即删；不入库）
TS_AUTHKEY_FILE="${TS_AUTHKEY_FILE:-}"
# 锁定 home-manager / system-manager 驱动版本（与 flake.lock 对齐，避免版本漂移）
HM_REV="${HM_REV:-a1645f407776}"
SM_REV="${SM_REV:-48d47346e0c6}"
HM_BACKUP_EXT="${HM_BACKUP_EXT:-hm.bak}"
# UID/GID：默认 1001——Tencent Lighthouse 镜像预建 lighthouse(1000)，避免冲突。
UID_LUCK="${UID_LUCK:-1001}"
GID_LUCK="${GID_LUCK:-1001}"
# sops 验证用 user secret
VERIFY_SECRET="${VERIFY_SECRET:-GITHUB_TOKEN}"
# 步骤开关（便于分步重跑）
DO_SSHD_LOCK="${DO_SSHD_LOCK:-1}"

log() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
die() { echo "error: $*" >&2; exit 1; }

: "${ROOT_PASS:?set ROOT_PASS (initial root password)}"
command -v sshpass >/dev/null || die "sshpass not found"
[[ -f ${PUBKEY} ]] || die "PUBKEY missing: ${PUBKEY}"
[[ -f ${AGE_KEY} ]] || die "AGE_KEY missing: ${AGE_KEY}"
[[ -f ${FLAKE_SRC}/flake.nix ]] || die "FLAKE_SRC=${FLAKE_SRC} is not a flake root"
[[ -f ${FLAKE_SRC}/flake.lock ]] || die "FLAKE_SRC=${FLAKE_SRC} missing flake.lock"

# SSH helpers（root 用密码，luck 用 key）
RSSH() {
  SSHPASS="${ROOT_PASS}" sshpass -e ssh \
    -o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 \
    "root@${HOST}" "$@"
}
LSSH() {
  ssh -o BatchMode=yes -o ConnectTimeout=20 -o StrictHostKeyChecking=accept-new \
    "${USERNAME}@${HOST}" "$@"
}

# ---- 0. 探测 ----
log "preflight ${HOST}"
RSSH 'echo root_ok; grep -E "^(PRETTY_NAME|VERSION_ID)" /etc/os-release'

# ---- 1. 建 luck 用户 + sudo(NOPASSWD) + authorized_keys ----
log "ensure user ${USERNAME} (${UID_LUCK}:${GID_LUCK})"
RSSH "bash -lc '
  set -euo pipefail
  if ! getent group ${GID_LUCK} >/dev/null 2>&1; then groupadd -g ${GID_LUCK} ${USERNAME}; fi
  if ! id -u ${USERNAME} >/dev/null 2>&1; then
    useradd -m -u ${UID_LUCK} -g ${GID_LUCK} -s /bin/bash ${USERNAME}
  fi
  mkdir -p /home/${USERNAME}/.ssh
  chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
  usermod -aG sudo ${USERNAME} || true
  # NOPASSWD sudo：sm 系统 profile / system-manager 需要 root 激活（与容器约定一致）
  printf \"%s ALL=(ALL) NOPASSWD:ALL\n\" \"${USERNAME}\" > /etc/sudoers.d/${USERNAME}
  chmod 440 /etc/sudoers.d/${USERNAME}
  id ${USERNAME}
'"
# push pubkey
SSHPASS="${ROOT_PASS}" sshpass -e scp \
  -o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 \
  "${PUBKEY}" "root@${HOST}:/home/${USERNAME}/.ssh/authorized_keys"
RSSH "chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh/authorized_keys && chmod 600 /home/${USERNAME}/.ssh/authorized_keys"

# ---- 2. 验证 luck+key 登录（非交互，失败即中止，绝不自锁） ----
log "verify ${USERNAME} key login"
LSSH 'id; sudo -n true && echo sudo_nopasswd_ok'

# ---- 3. 安装 Determinate Nix（多用户） ----
log "install Determinate multi-user Nix"
if RSSH 'command -v nix >/dev/null 2>&1 && nix --version'; then
  log "nix already present"
else
  RSSH "bash -lc '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq curl ca-certificates xz-utils rsync >/dev/null
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install \
      --no-confirm \
      --extra-conf \"trusted-users = root ${USERNAME}\" \
      --extra-conf \"experimental-features = nix-command flakes\"
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
      ln -sfn /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh /etc/profile.d/nix-daemon.sh || true
    fi
  '"
  RSSH 'bash -lc ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; nix --version"'
fi

# ---- 4. 同步 flake 到目标机 ----
log "rsync flake -> ${REMOTE_FLAKE}"
RSSH "mkdir -p ${REMOTE_FLAKE}"
# 排除重目录与本地专属；保留 secrets/（sops 需要）与 .cntr（home/core/devops/cntr.nix 引用）。
SSHPASS="${ROOT_PASS}" sshpass -e rsync -a --delete \
  -e "ssh -o StrictHostKeyChecking=accept-new" \
  --exclude='.git' --exclude='.claude' --exclude='.worktrees' \
  --exclude='result' --exclude='results' --exclude='docs' \
  --exclude='.ruff_cache' --exclude='.direnv' \
  --exclude='.apm' --exclude='.tms' \
  "${FLAKE_SRC}/" "root@${HOST}:${REMOTE_FLAKE}/"
RSSH "chown -R ${USERNAME}:${USERNAME} ${REMOTE_FLAKE}"

# ---- 5. push age key（standalone HM 的 sops 激活需要） ----
log "install age key for ${USERNAME}"
RSSH "mkdir -p /home/${USERNAME}/.config/sops/age && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config"
SSHPASS="${ROOT_PASS}" sshpass -e scp \
  -o StrictHostKeyChecking=accept-new \
  "${AGE_KEY}" "root@${HOST}:/home/${USERNAME}/.config/sops/age/keys.txt"
RSSH "chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.config/sops/age/keys.txt && chmod 600 /home/${USERNAME}/.config/sops/age/keys.txt"

# ---- 6. linger + 用户 systemd（sops user service 需要） ----
log "enable linger + user manager for ${USERNAME}"
RSSH "bash -lc '
  loginctl enable-linger ${USERNAME} || true
  systemctl start user@${UID_LUCK}.service 2>/dev/null || true
  for _ in 1 2 3 4 5 6 7 8; do [[ -S /run/user/${UID_LUCK}/bus ]] && break; sleep 1; done
  ls /run/user/${UID_LUCK}/bus && echo bus_ok
'"

# ---- 7. standalone HM switch（以 luck 身份；驱动用锁定 HM rev） ----
log "home-manager switch --flake ${REMOTE_FLAKE}#${NODE}"
LSSH "bash -lc '
  set -euo pipefail
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  export HOME=/home/${USERNAME}
  export USER=${USERNAME}
  export HOME_MANAGER_BACKUP_EXT=${HM_BACKUP_EXT}
  if [[ -S /run/user/${UID_LUCK}/bus ]]; then
    export XDG_RUNTIME_DIR=/run/user/${UID_LUCK}
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${UID_LUCK}/bus
  fi
  cd ${REMOTE_FLAKE}
  nix run github:nix-community/home-manager/${HM_REV} -- switch \
    --flake ${REMOTE_FLAKE}#${NODE} -b ${HM_BACKUP_EXT}
'"

# ---- 8. system-manager switch（root 激活；驱动用锁定 SM rev） ----
log "system-manager switch --flake ${REMOTE_FLAKE}#${NODE}"
LSSH "bash -lc '
  set -euo pipefail
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  export HOME=/home/${USERNAME}
  cd ${REMOTE_FLAKE}
  # sudo 重置 PATH 后 nix 不在其中：用完整二进制路径（multi-user Nix 固定位置）。
  sudo -n /nix/var/nix/profiles/default/bin/nix run github:numtide/system-manager/${SM_REV} -- switch \
    --flake ${REMOTE_FLAKE}#${NODE}
'"

# ---- 9. tailscale（官方脚本 + 一次性 authkey；root） ----
log "tailscale install + up"
if RSSH 'command -v tailscale >/dev/null 2>&1'; then
  log "tailscale already installed"
else
  RSSH "bash -lc '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    curl -fsSL https://tailscale.com/install.sh | sh
  '"
fi
if [[ -n ${TS_AUTHKEY_FILE} && -f ${TS_AUTHKEY_FILE} ]]; then
  # authkey 经 scp 送 root，up 后删除（不入库、不留盘）
  SSHPASS="${ROOT_PASS}" sshpass -e scp \
    -o StrictHostKeyChecking=accept-new \
    "${TS_AUTHKEY_FILE}" "root@${HOST}:/root/.ts-authkey"
  RSSH "chmod 600 /root/.ts-authkey"
  RSSH "tailscale up --authkey-file=/root/.ts-authkey || tailscale up --authkey=\$(cat /root/.ts-authkey); rm -f /root/.ts-authkey; tailscale status | head -5"
else
  log "WARN: no TS_AUTHKEY_FILE; tailscale up 请手动执行（交互登录）"
fi

# ---- 10. sops 验证（用户向 secret 可读） ----
log "verify sops secret ${VERIFY_SECRET}"
LSSH "bash -lc '
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
  export HOME=/home/${USERNAME}
  if [[ -S /run/user/${UID_LUCK}/bus ]]; then
    export XDG_RUNTIME_DIR=/run/user/${UID_LUCK}
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${UID_LUCK}/bus
    systemctl --user start sops-nix.service 2>/dev/null || true
  fi
  sleep 2
  p=\$HOME/.config/sops-nix/secrets/${VERIFY_SECRET}
  if [[ -r \$p && -s \$p ]]; then echo \"sops_ok: ${VERIFY_SECRET} readable\"; else echo \"WARN: ${VERIFY_SECRET} not readable\"; fi
  ls \$HOME/.config/sops-nix/secrets/ 2>/dev/null | head -8
'"

# ---- 11. 锁 sshd（仅在 luck+key 已验证后） ----
if [[ ${DO_SSHD_LOCK} == "1" ]]; then
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
  # 锁后立即验证 luck 仍能登录
  sleep 1
  log "verify luck still logs in after hardening"
  LSSH 'id' || die "post-hardening luck login failed!"
  # root 密码登录应失败
  if SSHPASS="${ROOT_PASS}" sshpass -e ssh -o BatchMode=yes -o ConnectTimeout=8 \
    -o StrictHostKeyChecking=accept-new "root@${HOST}" 'echo root_still_ok' 2>/dev/null; then
    echo "WARN: root password login still works (unexpected)"
  else
    log "root password login disabled (expected)"
  fi
fi

log "phase8-real bootstrap done for ${NODE} (${HOST})"
