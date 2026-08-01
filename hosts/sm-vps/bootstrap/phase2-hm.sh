#!/usr/bin/env bash
# Phase 2: Incus 容器内多用户 Nix + standalone home-manager switch (sm-vps-lab).
# 在宿主 nixos-vps-dev 上执行（需 incus + 容器 root）。
# 幂等；不 commit、不写 docs/。
set -euo pipefail

CONTAINER="${CONTAINER:-linux-sm-lab}"
# 宿主上的 flake 工作树（Phase 未合入主 clone 时用 dotfiles-sm）
FLAKE_SRC="${FLAKE_SRC:-}"
if [[ -z ${FLAKE_SRC} ]]; then
  if [[ -f /home/luck/Desktop/dotfiles-sm/flake.nix ]]; then
    FLAKE_SRC=/home/luck/Desktop/dotfiles-sm
  elif [[ -f /home/luck/Desktop/dotfiles/flake.nix ]]; then
    FLAKE_SRC=/home/luck/Desktop/dotfiles
  else
    echo "error: set FLAKE_SRC to a flake checkout on the host" >&2
    exit 1
  fi
fi

FLAKE_ATTR="${FLAKE_ATTR:-sm-vps-lab}"
# 容器内 flake 路径（luck 家目录下，与 globals.workspace 对齐）
CT_FLAKE="${CT_FLAKE:-/home/luck/Desktop/dotfiles}"
HM_BACKUP_EXT="${HM_BACKUP_EXT:-hm.bak}"
USERNAME="${USERNAME:-luck}"
# 与宿主 luck 对齐（HM 不强制 uid，但 POC 约定 U3）
CT_UID="${CT_UID:-1000}"
CT_GID="${CT_GID:-1000}"
# 宿主 age key（sops 激活需要）；正式可重复流程见 phase3-sops.sh
HOST_AGE_KEY="${HOST_AGE_KEY:-/home/luck/.config/sops/age/keys.txt}"

log() { printf '+ %s\n' "$*"; }
cexec() { incus exec "${CONTAINER}" -- "$@"; }
# login shell so /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 生效
cbash() { incus exec "${CONTAINER}" -- bash -lc "$*"; }

need_host() {
  command -v incus >/dev/null || {
    echo "error: incus not found (run on nixos-vps-dev)" >&2
    exit 1
  }
  incus info "${CONTAINER}" >/dev/null || {
    echo "error: container ${CONTAINER} missing" >&2
    exit 1
  }
  [[ -f "${FLAKE_SRC}/flake.nix" ]] || {
    echo "error: FLAKE_SRC=${FLAKE_SRC} is not a flake" >&2
    exit 1
  }
}

ensure_container_running() {
  local state
  state="$(incus list "${CONTAINER}" -c s --format csv)"
  if [[ ${state} != "RUNNING" ]]; then
    log "starting ${CONTAINER}"
    incus start "${CONTAINER}"
  fi
}

# 1) 用户 luck + home
ensure_user() {
  log "ensure user ${USERNAME} (uid=${CT_UID}) in ${CONTAINER}"
  cexec bash -c "
    set -euo pipefail
    if ! getent group ${CT_GID} >/dev/null 2>&1; then
      groupadd -g ${CT_GID} ${USERNAME} 2>/dev/null || groupadd ${USERNAME}
    fi
    if ! id -u ${USERNAME} >/dev/null 2>&1; then
      useradd -m -u ${CT_UID} -g ${CT_GID} -s /bin/bash ${USERNAME}
    fi
    # home 必须存在且属主正确（HM homeDirectory=/home/luck）
    mkdir -p /home/${USERNAME}
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
    # sudo 便于多用户 nix（Determinate 装好后 wheel/sudo 可选）
    if getent group sudo >/dev/null 2>&1; then
      usermod -aG sudo ${USERNAME} || true
    fi
    # linger：HM 的 sops-nix.service 是 user unit，无 user manager 时 activation 会跳过
    if command -v loginctl >/dev/null 2>&1; then
      loginctl enable-linger ${USERNAME} || true
    fi
    id ${USERNAME}
  "
}

# 2) 多用户 Nix（Determinate；已装则跳过）
ensure_nix() {
  if cbash 'command -v nix >/dev/null 2>&1 && nix --version'; then
    log "nix already present"
    return 0
  fi
  log "install Determinate multi-user Nix in ${CONTAINER}"
  # 官方 installer：no-start-daemon 后由我们 systemctl enable；容器内 PID1=systemd
  cexec bash -c '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq curl ca-certificates xz-utils sudo >/dev/null
    if [[ ! -x /nix/var/nix/profiles/default/bin/nix ]] && ! command -v nix >/dev/null 2>&1; then
      curl -fsSL https://install.determinate.systems/nix | sh -s -- install \
        --no-confirm \
        --extra-conf "trusted-users = root luck" \
        --extra-conf "experimental-features = nix-command flakes"
    fi
    # daemon
    if systemctl list-unit-files nix-daemon.service >/dev/null 2>&1; then
      systemctl enable --now nix-daemon.service || systemctl restart nix-daemon.service || true
    fi
    # profile for non-login
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
      ln -sfn /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh /etc/profile.d/nix-daemon.sh || true
    fi
  '
  cbash 'nix --version'
}

# 3) flake：rsync 宿主树 → 容器（避免 idmap 下挂宿主 /nix；只同步源码）
sync_flake() {
  log "sync flake ${FLAKE_SRC} -> ${CONTAINER}:${CT_FLAKE}"
  cexec bash -c "mkdir -p $(dirname "${CT_FLAKE}") && mkdir -p ${CT_FLAKE}"
  # 排除 store 产物与重目录；保留 secrets yaml（sops 模块需要 defaultSopsFile）
  incus exec "${CONTAINER}" -- bash -c "rm -rf ${CT_FLAKE}.partial && mkdir -p ${CT_FLAKE}.partial"
  # tar over incus exec stdin（无需容器内 rsync/sshd）
  tar -C "${FLAKE_SRC}" \
    --exclude='.git' \
    --exclude='result' \
    --exclude='results' \
    --exclude='docs' \
    --exclude='.ruff_cache' \
    --exclude='.direnv' \
    -cf - . |
    cexec bash -c "tar -C ${CT_FLAKE}.partial -xf - && rm -rf ${CT_FLAKE} && mv ${CT_FLAKE}.partial ${CT_FLAKE} && chown -R ${USERNAME}:${USERNAME} ${CT_FLAKE}"
  cbash "test -f ${CT_FLAKE}/flake.nix && echo flake_ok"
}

# 4) sops age key（与 secrets/default.nix linux path 一致；正式验收见 phase3-sops.sh）
sync_age_key() {
  if [[ ! -f ${HOST_AGE_KEY} ]]; then
    log "WARN: no HOST_AGE_KEY at ${HOST_AGE_KEY}; sops activation may fail (run phase3-sops.sh)"
    return 0
  fi
  log "install age key for ${USERNAME} → ~/.config/sops/age/keys.txt"
  local ct_key_dir="/home/${USERNAME}/.config/sops/age"
  cexec bash -c "mkdir -p ${ct_key_dir} && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config"
  incus file push --uid "${CT_UID}" --gid "${CT_GID}" --mode 0600 \
    "${HOST_AGE_KEY}" "${CONTAINER}${ct_key_dir}/keys.txt"
  cexec bash -c "chown ${USERNAME}:${USERNAME} ${ct_key_dir}/keys.txt && chmod 600 ${ct_key_dir}/keys.txt"
}

# 5) home-manager switch（容器内、以 luck 身份）
hm_switch() {
  log "home-manager switch --flake ${CT_FLAKE}#${FLAKE_ATTR} -b ${HM_BACKUP_EXT}"
  # nix-daemon + flakes；HOME 钉死；备份后缀与 homeStandalone.backupFileExtension 一致
  cexec bash -c "
    set -euo pipefail
    # root 侧确保 daemon 起来
    if systemctl is-active nix-daemon >/dev/null 2>&1 || systemctl start nix-daemon 2>/dev/null; then
      true
    fi
    # 先有 user manager，activation 里 sops-nix / reloadSystemd 才不 skip
    loginctl enable-linger ${USERNAME} || true
    systemctl start user@${CT_UID}.service 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8; do
      [[ -S /run/user/${CT_UID}/bus ]] && break
      sleep 1
    done
    # luck 的 nix 环境 + 会话 bus（sops user service）
    runuser -u ${USERNAME} -- bash -lc '
      set -euo pipefail
      export HOME=/home/${USERNAME}
      export USER=${USERNAME}
      export HOME_MANAGER_BACKUP_EXT=${HM_BACKUP_EXT}
      if [[ -S /run/user/${CT_UID}/bus ]]; then
        export XDG_RUNTIME_DIR=/run/user/${CT_UID}
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CT_UID}/bus
      fi
      # Determinate / multi-user profile
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
      cd ${CT_FLAKE}
      nix --version
      # 优先 nix run home-manager（不依赖已有 hm CLI）
      nix run home-manager/master -- switch --flake ${CT_FLAKE}#${FLAKE_ATTR} -b ${HM_BACKUP_EXT}
    '
  "
}

# switch 后：拉起 user manager + sops-nix（首次无 linger 时 activation 会 skip）
post_activate_sops() {
  log "best-effort: user systemd + sops-nix for ${USERNAME}"
  cexec bash -c "
    set -euo pipefail
    loginctl enable-linger ${USERNAME} || true
    systemctl start user@${CT_UID}.service 2>/dev/null || true
    # 等 runtime dir
    for _ in 1 2 3 4 5; do
      [[ -S /run/user/${CT_UID}/bus ]] && break
      sleep 1
    done
    if [[ -S /run/user/${CT_UID}/bus ]]; then
      runuser -u ${USERNAME} -- env \
        XDG_RUNTIME_DIR=/run/user/${CT_UID} \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CT_UID}/bus \
        systemctl --user daemon-reload || true
      runuser -u ${USERNAME} -- env \
        XDG_RUNTIME_DIR=/run/user/${CT_UID} \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CT_UID}/bus \
        systemctl --user start sops-nix.service || true
      ls /home/${USERNAME}/.config/sops-nix/secrets 2>/dev/null | head -5 || true
    else
      echo 'WARN: no user bus; sops deferred — run phase3-sops.sh' >&2
    fi
  " || log "WARN: post_activate_sops non-fatal"
}

verify() {
  log "verify milestones in ${CONTAINER}"
  cbash 'nix --version'
  cexec bash -c "
    runuser -u ${USERNAME} -- bash -lc '
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
      export HOME=/home/${USERNAME}
      export PATH=\"\$HOME/.nix-profile/bin:\$PATH\"
      echo \"=== nix-profile ===\"
      readlink -f ~/.nix-profile || readlink ~/.nix-profile || true
      ls -la ~/.nix-profile/bin/zsh ~/.nix-profile/bin/home-manager 2>/dev/null || true
      echo \"=== generations ===\"
      home-manager generations 2>/dev/null || true
      echo \"=== which zsh/hm ===\"
      command -v zsh || true
      command -v home-manager || true
    '
  "
}

main() {
  need_host
  ensure_container_running
  ensure_user
  ensure_nix
  sync_flake
  sync_age_key
  hm_switch
  post_activate_sops
  verify
  log "Phase 2 bootstrap done"
}

main "$@"
