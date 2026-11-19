#!/usr/bin/env bash
# Restore the hm-only user-level workbench state on a vendor PA.
#
# Run as root after a container reboot or a platform image reset. The nix-portable
# store, HM generation, sops key, and hc wrappers live under /root and persist;
# /nix, /usr/local/bin links, the user manager, /etc/passwd shell, and the Nezha
# system unit may need to be recreated.
#
# Usage: ./restore.sh [/nix/store/...-home-manager-generation]
#   Default generation: /root/.hm-generation
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

log() { printf '[hm-restore] %s\n' "$*"; }
warn() { printf '[hm-restore] WARN: %s\n' "$*" >&2; }
die() {
  printf '[hm-restore] ERROR: %s\n' "$*" >&2
  exit 1
}

[[ "$(id -u)" -eq 0 ]] || die "run as root"

HM_GEN="${1:-}"
if [[ -z $HM_GEN ]]; then
  [[ -f /root/.hm-generation ]] || die "no generation given and /root/.hm-generation is missing"
  HM_GEN="$(cat /root/.hm-generation)"
fi
[[ -x "$HM_GEN/activate" ]] || die "invalid HM generation: $HM_GEN"

# /nix may be missing or a dangling symlink after an image reset.
if [[ -L /nix && ! -e /nix ]]; then
  rm -f /nix
  ln -s /root/.nix-portable/nix /nix
  log "recreated /nix -> /root/.nix-portable/nix"
elif [[ ! -e /nix ]]; then
  [[ -d /root/.nix-portable/nix ]] || die "/root/.nix-portable/nix is missing"
  ln -s /root/.nix-portable/nix /nix
  log "created /nix -> /root/.nix-portable/nix"
fi

# nix-portable does not put nix-env on PATH; HM activation needs it.
if [[ -x /root/.local/bin/nix-portable ]]; then
  for c in nix nix-env nix-store nix-build; do
    cat >"/root/.local/bin/$c" <<EOF
#!/usr/bin/env bash
exec /root/.local/bin/nix-portable $c "\$@"
EOF
    chmod 0755 "/root/.local/bin/$c"
  done
  log "refreshed nix-portable command wrappers"
else
  warn "/root/.local/bin/nix-portable missing; HM activation may fail"
fi

# Default PATH for non-interactive SSH (herdr-app).
for c in hc herdr-core; do
  if [[ -e "/root/.local/bin/$c" ]]; then
    ln -sfn "/root/.local/bin/$c" "/usr/local/bin/$c"
    log "linked /usr/local/bin/$c"
  else
    warn "/root/.local/bin/$c missing"
  fi
done

# Standard user manager (hm-only). Installing libpam-systemd upgrades systemd;
# this is the same trade-off as `bootstrap.sh --user-manager`.
if ! find /usr/lib -name pam_systemd.so -print -quit 2>/dev/null | grep -q .; then
  log "installing libpam-systemd (hm-only system-level change)"
  apt-get update -qq || warn "apt-get update failed; trying install anyway"
  DEBIAN_FRONTEND=noninteractive apt-get install -y libpam-systemd
fi
mkdir -p /run/user/0
chmod 700 /run/user/0
loginctl enable-linger root 2>/dev/null || warn "could not enable linger for root"
systemctl start user@0.service 2>/dev/null || warn "could not start user@0.service"
XDG_RUNTIME_DIR=/run/user/0 systemctl --user is-system-running 2>/dev/null ||
  warn "systemctl --user is not running"

# HM activation renders sops secrets, zsh/atuin/gh config, and the Nezha config.
log "activating $HM_GEN"
HOME=/root USER=root XDG_RUNTIME_DIR=/run/user/0 PATH=/root/.local/bin:$PATH \
  "$HM_GEN/activate"

usermod -s /root/.nix-profile/bin/zsh root 2>/dev/null || warn "could not set root shell to zsh"

# Nezha system unit. Keep a copy of nezha-agent.service next to this script.
if [[ -f "$SCRIPT_DIR/nezha-agent.service" ]]; then
  install -m 644 "$SCRIPT_DIR/nezha-agent.service" /etc/systemd/system/nezha-agent.service
  systemctl daemon-reload
  systemctl enable --now nezha-agent.service 2>/dev/null ||
    warn "nezha-agent.service did not start yet; check its config"
else
  warn "nezha-agent.service not found next to restore.sh; skipping"
fi

log "verification"
hc --version 2>/dev/null || warn "hc not found"
herdr-core --version 2>/dev/null || warn "herdr-core not found"
getent passwd root
log "done; verify herdr-app machine list and Nezha dashboard"
