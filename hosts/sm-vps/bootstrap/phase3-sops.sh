#!/usr/bin/env bash
# Phase 3: standalone HM 用户向 sops 正式路径（可重复、可验证）
# 在宿主 nixos-vps-dev 上执行（需 incus + 容器 linux-sm-lab）。
# 依赖 Phase 2（Nix + HM generation 至少 1 次）；不 commit、不写 docs/。
#
# 约定（与 secrets/default.nix linux age.keyFile 对齐）：
#   容器 luck: ~/.config/sops/age/keys.txt  →  /home/luck/.config/sops/age/keys.txt
#   解密产物:  ~/.config/sops-nix/secrets/<NAME>  （symlink → /run/user/UID/secrets.d/N）
#
# 宿主 → 容器放置 age key（从宿主已有 key 拷贝；不在仓库内提交 key）：
#   HOST_AGE_KEY 默认 /home/luck/.config/sops/age/keys.txt
set -euo pipefail

CONTAINER="${CONTAINER:-linux-sm-lab}"
FLAKE_SRC="${FLAKE_SRC:-}"
if [[ -z "${FLAKE_SRC}" ]]; then
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
CT_FLAKE="${CT_FLAKE:-/home/luck/Desktop/dotfiles}"
HM_BACKUP_EXT="${HM_BACKUP_EXT:-hm.bak}"
USERNAME="${USERNAME:-luck}"
CT_UID="${CT_UID:-1000}"
CT_GID="${CT_GID:-1000}"
# 与 secrets/default.nix: age.keyFile = /home/<user>/.config/sops/age/keys.txt
HOST_AGE_KEY="${HOST_AGE_KEY:-/home/luck/.config/sops/age/keys.txt}"
CT_AGE_DIR="/home/${USERNAME}/.config/sops/age"
CT_AGE_KEY="${CT_AGE_DIR}/keys.txt"
# 验证用：至少一个 user secret（勿用 root-only 系统 secret 作为唯一目标；这里用 GITHUB_TOKEN）
VERIFY_SECRET="${VERIFY_SECRET:-GITHUB_TOKEN}"
CT_SECRET_LINK="/home/${USERNAME}/.config/sops-nix/secrets/${VERIFY_SECRET}"
SYNC_FLAKE="${SYNC_FLAKE:-1}"
RUN_HM_SWITCH="${RUN_HM_SWITCH:-1}"

log() { printf '+ %s\n' "$*"; }
die() { echo "error: $*" >&2; exit 1; }
cexec() { incus exec "${CONTAINER}" -- "$@"; }
cbash() { incus exec "${CONTAINER}" -- bash -lc "$*"; }

need_host() {
  command -v incus >/dev/null || die "incus not found (run on nixos-vps-dev)"
  incus info "${CONTAINER}" >/dev/null || die "container ${CONTAINER} missing"
  [[ -f "${HOST_AGE_KEY}" ]] || die "HOST_AGE_KEY missing: ${HOST_AGE_KEY}"
  [[ -f "${FLAKE_SRC}/flake.nix" ]] || die "FLAKE_SRC=${FLAKE_SRC} is not a flake"
}

ensure_container_running() {
  local state
  state="$(incus list "${CONTAINER}" -c s --format csv)"
  if [[ "${state}" != "RUNNING" ]]; then
    log "starting ${CONTAINER}"
    incus start "${CONTAINER}"
  fi
}

# 1) age key：可重复从宿主推入容器约定路径（mode 600、属主 luck）
install_age_key() {
  log "install age key → ${CONTAINER}:${CT_AGE_KEY} (from ${HOST_AGE_KEY})"
  cexec bash -c "
    set -euo pipefail
    id -u ${USERNAME} >/dev/null
    mkdir -p ${CT_AGE_DIR}
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config
  "
  # incus file push 覆盖；随后收紧权限（宿主 key 可能是 644）
  incus file push --uid "${CT_UID}" --gid "${CT_GID}" --mode 0600 \
    "${HOST_AGE_KEY}" "${CONTAINER}${CT_AGE_KEY}"
  cexec bash -c "
    set -euo pipefail
    chown ${USERNAME}:${USERNAME} ${CT_AGE_KEY}
    chmod 600 ${CT_AGE_KEY}
    test -r ${CT_AGE_KEY}
    test -s ${CT_AGE_KEY}
    # 非空且含 AGE-SECRET-KEY 行（不打印 key 内容）
    grep -q '^AGE-SECRET-KEY-' ${CT_AGE_KEY}
    stat -c 'age_key mode=%a owner=%U:%G size=%s' ${CT_AGE_KEY}
  "
}

# 2) linger + user@UID：sops-nix 是 user unit；无 user manager 则 activation 跳过
ensure_user_systemd() {
  log "enable linger + start user@${CT_UID} for ${USERNAME}"
  cexec bash -c "
    set -euo pipefail
    if ! command -v loginctl >/dev/null 2>&1; then
      echo 'error: loginctl missing (need systemd-logind)' >&2
      exit 1
    fi
    loginctl enable-linger ${USERNAME}
    systemctl start user@${CT_UID}.service
    for _ in \$(seq 1 15); do
      [[ -S /run/user/${CT_UID}/bus ]] && break
      sleep 1
    done
    [[ -S /run/user/${CT_UID}/bus ]] || {
      echo 'error: /run/user/${CT_UID}/bus not ready' >&2
      exit 1
    }
    loginctl show-user ${USERNAME} -p Linger -p State -p RuntimePath
  "
}

# 3) 可选：同步 flake（与 phase2 相同 tar 管道；默认开，保证 secrets.nix 与脚本一致）
sync_flake() {
  [[ "${SYNC_FLAKE}" == "1" ]] || {
    log "skip flake sync (SYNC_FLAKE=${SYNC_FLAKE})"
    return 0
  }
  log "sync flake ${FLAKE_SRC} -> ${CONTAINER}:${CT_FLAKE}"
  cexec bash -c "mkdir -p $(dirname "${CT_FLAKE}") && rm -rf ${CT_FLAKE}.partial && mkdir -p ${CT_FLAKE}.partial"
  tar -C "${FLAKE_SRC}" \
    --exclude='.git' \
    --exclude='result' \
    --exclude='results' \
    --exclude='docs' \
    --exclude='.ruff_cache' \
    --exclude='.direnv' \
    -cf - . \
    | cexec bash -c "tar -C ${CT_FLAKE}.partial -xf - && rm -rf ${CT_FLAKE} && mv ${CT_FLAKE}.partial ${CT_FLAKE} && chown -R ${USERNAME}:${USERNAME} ${CT_FLAKE}"
  cbash "test -f ${CT_FLAKE}/flake.nix && echo flake_ok"
}

# 4) home-manager switch（激活脚本会触发 sops-install-secrets / sops-nix.service）
hm_switch() {
  [[ "${RUN_HM_SWITCH}" == "1" ]] || {
    log "skip hm switch (RUN_HM_SWITCH=${RUN_HM_SWITCH})"
    return 0
  }
  log "home-manager switch --flake ${CT_FLAKE}#${FLAKE_ATTR} -b ${HM_BACKUP_EXT}"
  cexec bash -c "
    set -euo pipefail
    systemctl is-active nix-daemon >/dev/null 2>&1 || systemctl start nix-daemon
    loginctl enable-linger ${USERNAME} || true
    systemctl start user@${CT_UID}.service
    for _ in \$(seq 1 10); do
      [[ -S /run/user/${CT_UID}/bus ]] && break
      sleep 1
    done
    runuser -u ${USERNAME} -- bash -lc '
      set -euo pipefail
      export HOME=/home/${USERNAME}
      export USER=${USERNAME}
      export HOME_MANAGER_BACKUP_EXT=${HM_BACKUP_EXT}
      export XDG_RUNTIME_DIR=/run/user/${CT_UID}
      export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CT_UID}/bus
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
      cd ${CT_FLAKE}
      nix run home-manager/master -- switch --flake ${CT_FLAKE}#${FLAKE_ATTR} -b ${HM_BACKUP_EXT}
    '
  "
}

# 5) 显式拉起 sops-nix（switch 后 / 或仅 key 更新后）
start_sops_nix() {
  log "systemctl --user start sops-nix.service"
  cexec bash -c "
    set -euo pipefail
    [[ -S /run/user/${CT_UID}/bus ]] || systemctl start user@${CT_UID}.service
    for _ in \$(seq 1 10); do
      [[ -S /run/user/${CT_UID}/bus ]] && break
      sleep 1
    done
    runuser -u ${USERNAME} -- env \
      XDG_RUNTIME_DIR=/run/user/${CT_UID} \
      DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CT_UID}/bus \
      systemctl --user daemon-reload
    runuser -u ${USERNAME} -- env \
      XDG_RUNTIME_DIR=/run/user/${CT_UID} \
      DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CT_UID}/bus \
      systemctl --user enable --now sops-nix.service
    # oneshot：Active=inactive + Result=success 即成功
    runuser -u ${USERNAME} -- env \
      XDG_RUNTIME_DIR=/run/user/${CT_UID} \
      DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CT_UID}/bus \
      systemctl --user start sops-nix.service
    runuser -u ${USERNAME} -- env \
      XDG_RUNTIME_DIR=/run/user/${CT_UID} \
      DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CT_UID}/bus \
      systemctl --user show sops-nix.service -p Result -p ExecMainStatus -p ActiveState
  "
}

# 6) Milestone 验证
verify() {
  log "verify Phase 3 milestones in ${CONTAINER}"
  cexec bash -c "
    set -euo pipefail
    runuser -u ${USERNAME} -- env \
      HOME=/home/${USERNAME} \
      XDG_RUNTIME_DIR=/run/user/${CT_UID} \
      DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CT_UID}/bus \
      bash -lc '
        set -euo pipefail
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
        export PATH=\"\$HOME/.nix-profile/bin:\$PATH\"

        echo \"=== age key ===\"
        test -r \"\$HOME/.config/sops/age/keys.txt\"
        test -s \"\$HOME/.config/sops/age/keys.txt\"
        stat -c \"OK age_key mode=%a size=%s\" \"\$HOME/.config/sops/age/keys.txt\"

        echo \"=== secret ${VERIFY_SECRET} ===\"
        # sops-nix HM 默认 symlink: ~/.config/sops-nix/secrets/<name>
        sp=\"\$HOME/.config/sops-nix/secrets/${VERIFY_SECRET}\"
        test -e \"\$sp\" || { echo \"missing \$sp\"; ls -la \"\$HOME/.config/sops-nix/secrets\" 2>/dev/null || true; exit 1; }
        test -r \"\$sp\"
        test -s \"\$sp\"
        sz=\$(wc -c < \"\$sp\" | tr -d \" \")
        echo \"OK secret path=\$sp size=\$sz\"

        echo \"=== linger / sops unit ===\"
        # linger 在 root 侧查；此处只查 user unit
        systemctl --user is-enabled sops-nix.service
        systemctl --user show sops-nix.service -p Result -p ExecMainStatus

        echo \"=== hm generations ===\"
        home-manager generations 2>/dev/null | head -3 || true
      '
  "
  log "verify OK (${VERIFY_SECRET} readable)"
}

main() {
  need_host
  ensure_container_running
  install_age_key
  ensure_user_systemd
  sync_flake
  hm_switch
  start_sops_nix
  verify
  log "Phase 3 sops path done"
}

main "$@"
