#!/usr/bin/env bash
# hm-lightvela user-level bootstrap (vendor-managed Vela workbench).
#
# Installs Nix (system Nix if present, otherwise nix-portable) and herdr-core
# into the current user's HOME. It does NOT touch /etc, sshd, systemd system
# units, tailscale, sops, or the platform-managed root filesystem.
#
# Run as the account herdr-app will SSH as (likely root; desk also works).
# The platform container's /root and /home are on /dev/vdb, so this state
# survives a platform image reset; /nix on overlayfs may not.
#
# Usage:
#   ./bootstrap.sh [--check] [--ssh-key ~/.ssh/id_ed25519.pub]
#                  [--force] [--no-nix-portable] [--user-manager]
#
#   --check             only print diagnostics, do not install
#   --ssh-key PATH      append the public key to ~/.ssh/authorized_keys
#   --force             rewrite config and reinstall herdr-core
#   --no-nix-portable   fail instead of downloading nix-portable
#   --nix-portable-url  override the nix-portable download URL
#   --user-manager      hm-only: install libpam-systemd, enable linger, and
#                       start user@<uid>.service (system-level change)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_USER="$(id -un)"
TARGET_HOME="${HOME:?HOME is not set}"
# Keep all Nix user state under this HOME. Without this, an inherited
# XDG_STATE_HOME can make `nix profile` fall back to another user's profile.
export XDG_STATE_HOME="$TARGET_HOME/.local/state"
export XDG_DATA_HOME="$TARGET_HOME/.local/share"
export XDG_CACHE_HOME="$TARGET_HOME/.cache"
unset NIX_PROFILE
BIN_DIR="$TARGET_HOME/.local/bin"
PROFILE="$TARGET_HOME/.nix-profile"
CONFIG_DIR="$TARGET_HOME/.config/herdr-core"
CONFIG_FILE="$CONFIG_DIR/config.toml"
NIX_PORTABLE_URL="${NIX_PORTABLE_URL:-https://github.com/DavHau/nix-portable/releases/download/v012/nix-portable-x86_64}"
NIX_PORTABLE_BIN="$BIN_DIR/nix-portable"
SSH_KEY=""
CHECK_ONLY=0
FORCE=0
NO_NIX_PORTABLE=0
USER_MANAGER=0
NIX=()
NIX_SOURCE=""
NIX_FLAGS=(--extra-experimental-features "nix-command flakes" --accept-flake-config)

log() { printf '[hm-lightvela] %s\n' "$*"; }
warn() { printf '[hm-lightvela] WARN: %s\n' "$*" >&2; }
die() {
  printf '[hm-lightvela] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

  --check             only print diagnostics, do not install
  --ssh-key PATH      append the public key to ~/.ssh/authorized_keys
  --force             rewrite config and reinstall herdr-core
  --no-nix-portable   fail instead of downloading nix-portable
  --nix-portable-url  override the nix-portable download URL
  --user-manager      hm-only: install libpam-systemd, enable linger,
                      and start user@<uid>.service
  -h, --help          show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --ssh-key)
    SSH_KEY="${2:?--ssh-key needs a path}"
    shift 2
    ;;
  --check)
    CHECK_ONLY=1
    shift
    ;;
  --force)
    FORCE=1
    shift
    ;;
  --no-nix-portable)
    NO_NIX_PORTABLE=1
    shift
    ;;
  --nix-portable-url)
    NIX_PORTABLE_URL="${2:?--nix-portable-url needs a URL}"
    shift 2
    ;;
  --user-manager)
    USER_MANAGER=1
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    die "unknown argument: $1 (use --help)"
    ;;
  esac
done

prepend_path() {
  export PATH="$TARGET_HOME/.nix-profile/bin:$BIN_DIR:/nix/var/nix/profiles/default/bin:$PATH"
}

have() { command -v "$1" >/dev/null 2>&1; }

fetch() {
  local url="$1" out="$2"
  if have curl; then
    curl -fL --retry 3 --connect-timeout 15 -o "$out" "$url"
  elif have wget; then
    wget -O "$out" "$url"
  else
    die "curl or wget is required to download nix-portable"
  fi
}

resolve_nix() {
  if have nix; then
    NIX=(nix)
    NIX_SOURCE=system
    log "using system nix: $(nix --version 2>/dev/null || echo nix)"
    return 0
  fi
  if have nix-portable; then
    NIX=(nix-portable nix)
    NIX_SOURCE=nix-portable
    log "using nix-portable from PATH"
    return 0
  fi
  if [[ $NO_NIX_PORTABLE -eq 1 ]]; then
    die "nix not found and --no-nix-portable was given"
  fi
  if [[ ! -x $NIX_PORTABLE_BIN || $FORCE -eq 1 ]]; then
    log "downloading nix-portable to $NIX_PORTABLE_BIN"
    mkdir -p "$BIN_DIR"
    fetch "$NIX_PORTABLE_URL" "$NIX_PORTABLE_BIN.tmp"
    chmod 0755 "$NIX_PORTABLE_BIN.tmp"
    mv -f "$NIX_PORTABLE_BIN.tmp" "$NIX_PORTABLE_BIN"
  fi
  NIX=("$NIX_PORTABLE_BIN" nix)
  NIX_SOURCE=nix-portable
  log "using $NIX_PORTABLE_BIN"
}

herdr_installed() {
  "${NIX[@]}" profile list 2>/dev/null | grep -q 'herdr-core'
}

install_herdr() {
  if [[ $FORCE -eq 1 ]] && herdr_installed; then
    log "removing existing herdr-core profile entry"
    "${NIX[@]}" "${NIX_FLAGS[@]}" profile remove herdr-core >/dev/null 2>&1 || true
  fi
  if herdr_installed; then
    log "herdr-core already installed in $PROFILE"
    return 0
  fi
  log "installing herdr-core from numtide/llm-agents.nix into $PROFILE"
  "${NIX[@]}" "${NIX_FLAGS[@]}" profile install \
    'github:numtide/llm-agents.nix#herdr-core'
}

find_hc() {
  local candidate
  for candidate in \
    "$TARGET_HOME/.nix-profile/bin/hc" \
    "$TARGET_HOME/.local/state/nix/profiles/profile/bin/hc"; do
    if [[ -x $candidate ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  candidate="$(
    find -L "$TARGET_HOME/.nix-profile" "$TARGET_HOME/.nix-portable" \
      "$TARGET_HOME/.local/state/nix/profiles" \
      -type f -name hc -perm -u+x 2>/dev/null | head -n 1 || true
  )"
  if [[ -n $candidate ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  return 1
}

write_config() {
  mkdir -p "$CONFIG_DIR"
  if [[ -f $CONFIG_FILE && $FORCE -eq 0 ]]; then
    log "keeping existing $CONFIG_FILE"
    return 0
  fi
  if [[ -f "$SCRIPT_DIR/herdr-core.toml" ]]; then
    cp "$SCRIPT_DIR/herdr-core.toml" "$CONFIG_FILE"
  else
    printf 'restore_screen = true\n' >"$CONFIG_FILE"
  fi
  log "wrote $CONFIG_FILE"
}

ensure_path_block() {
  local file="$1"
  mkdir -p "$(dirname -- "$file")"
  if grep -q 'hm-lightvela PATH' "$file" 2>/dev/null; then
    return 0
  fi
  cat >>"$file" <<'EOF'

# >>> hm-lightvela PATH >>>
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# <<< hm-lightvela PATH <<<
EOF
  log "added ~/.local/bin to PATH in $file"
}

add_ssh_key() {
  local keyfile="$1"
  if [[ $keyfile != *.pub && -f "$keyfile.pub" ]]; then
    keyfile="$keyfile.pub"
  fi
  [[ -f $keyfile ]] || die "SSH public key not found: $keyfile"
  local key
  key="$(tr -d '\r' <"$keyfile" | head -n 1)"
  [[ $key == ssh-* ]] || die "not an SSH public key: $keyfile"
  mkdir -p "$TARGET_HOME/.ssh"
  chmod 700 "$TARGET_HOME/.ssh"
  touch "$TARGET_HOME/.ssh/authorized_keys"
  chmod 600 "$TARGET_HOME/.ssh/authorized_keys"
  if grep -qxF "$key" "$TARGET_HOME/.ssh/authorized_keys"; then
    log "SSH key already authorized"
    return 0
  fi
  printf '%s\n' "$key" >>"$TARGET_HOME/.ssh/authorized_keys"
  log "authorized SSH key in $TARGET_HOME/.ssh/authorized_keys"
}

setup_user_manager() {
  if [[ "$(id -u)" -ne 0 ]]; then
    die "--user-manager requires root (hm-only system setup)"
  fi
  local uid runtime
  uid="$(id -u)"
  runtime="/run/user/$uid"

  if ! find /usr/lib -name pam_systemd.so -print -quit 2>/dev/null | grep -q .; then
    have apt-get || die "pam_systemd.so missing and apt-get is unavailable"
    log "installing libpam-systemd (hm-only system-level change)"
    apt-get update -qq || warn "apt-get update failed; trying install anyway"
    DEBIAN_FRONTEND=noninteractive apt-get install -y libpam-systemd
  fi

  if ! systemctl is-active "user@$uid.service" >/dev/null 2>&1; then
    # Avoid two user managers if a previous manual systemd --user is present.
    pgrep -u "$uid" -f '/usr/lib/systemd/systemd --user' 2>/dev/null |
      xargs -r kill 2>/dev/null || true
    sleep 1
  fi

  mkdir -p "$runtime"
  chmod 700 "$runtime"
  loginctl enable-linger "$TARGET_USER" 2>/dev/null ||
    warn "loginctl enable-linger failed; user manager may not start at boot"
  systemctl start "user@$uid.service" 2>/dev/null ||
    warn "systemctl start user@$uid.service failed"
  XDG_RUNTIME_DIR="$runtime" systemctl --user is-system-running 2>/dev/null ||
    warn "systemctl --user is not running"
  loginctl show-user "$TARGET_USER" -p Linger 2>/dev/null || true
}

check() {
  log "user: $TARGET_USER (uid $(id -u))"
  log "home: $TARGET_HOME"
  log "arch: $(uname -m)"
  if have systemd-detect-virt; then
    log "virt: $(systemd-detect-virt 2>/dev/null || echo unknown)"
  fi
  if systemctl --user status >/dev/null 2>&1; then
    log "user systemd: OK"
  else
    warn "user systemd unavailable; herdr-core uses systemd-run --user"
  fi
  local linger
  linger="$(loginctl show-user "$TARGET_USER" -p Linger 2>/dev/null | cut -d= -f2 || true)"
  if [[ $linger == "yes" ]]; then
    log "linger: yes"
  else
    warn "linger: ${linger:-unknown}; run as root: loginctl enable-linger $TARGET_USER"
  fi
  if have hc; then
    log "hc: $(command -v hc)"
  else
    warn "hc: not on PATH"
  fi
  if [[ -f $CONFIG_FILE ]]; then
    log "config: $CONFIG_FILE"
  else
    warn "config: missing ($CONFIG_FILE)"
  fi
  if have tailscale; then
    tailscale status 2>/dev/null | head -n 3 || true
  else
    warn "tailscale: not on PATH"
  fi
}

prepend_path

if [[ $CHECK_ONLY -eq 1 ]]; then
  check
  exit 0
fi

check
resolve_nix
install_herdr
write_config

HC_BIN="$(find_hc)" || die "herdr-core installed but 'hc' was not found; inspect: ${NIX[*]} profile list"
HC_BIN="$(readlink -f "$HC_BIN" 2>/dev/null || printf '%s' "$HC_BIN")"

# nix-portable keeps its store under $HOME; the ELF interpreter and RPATH still
# use /nix/store. Make that visible to the outer namespace so `hc` can execute
# without `nix-portable nix shell` (which re-substitutes the bad cache).
if [[ $NIX_SOURCE == "nix-portable" ]]; then
  if [[ "$(id -u)" -eq 0 && ! -e /nix ]]; then
    ln -s "$TARGET_HOME/.nix-portable/nix" /nix
    log "created /nix -> $TARGET_HOME/.nix-portable/nix"
  elif [[ ! -e /nix ]]; then
    warn "nix-portable store is not visible at /nix; as root run: ln -s $TARGET_HOME/.nix-portable/nix /nix"
  fi
fi

mkdir -p "$BIN_DIR"
HC_DIR="$(dirname -- "$HC_BIN")"

# A user manager changes where `hc` looks for its core socket
# (/run/user/<uid>/herdr-core/default.sock vs the no-user-manager path under
# ~/.local/state). Pick whichever socket exists so both the app and CLI work.
write_hc_wrapper() {
  local target="$1" bin="$2"
  rm -f "$target"
  cat >"$target" <<EOF
#!/usr/bin/env bash
if [ -z "\${HC_SOCKET:-}" ]; then
  for s in "/run/user/\$(id -u)/herdr-core/default.sock" "$TARGET_HOME/.local/state/herdr-core/default/default.sock"; do
    if [ -S "\$s" ]; then export HC_SOCKET="\$s"; break; fi
  done
fi
exec "$bin" "\$@"
EOF
  chmod 0755 "$target"
}

write_hc_wrapper "$BIN_DIR/hc" "$HC_BIN"
log "wrote $BIN_DIR/hc wrapper -> $HC_BIN"

# herdr-app's remote command looks for `herdr-core`, not `hc`. Keep both names.
if [[ -x "$HC_DIR/herdr-core" ]]; then
  write_hc_wrapper "$BIN_DIR/herdr-core" "$HC_DIR/herdr-core"
  log "wrote $BIN_DIR/herdr-core wrapper -> $HC_DIR/herdr-core"
else
  warn "no herdr-core binary next to hc; herdr-app machine add will fail"
fi

# Non-interactive SSH has a narrow PATH that usually does not include
# ~/.local/bin. Put hc/herdr-core on the default PATH for herdr-app as well.
if [[ "$(id -u)" -eq 0 && -d /usr/local/bin && -w /usr/local/bin ]]; then
  ln -sfn "$BIN_DIR/hc" /usr/local/bin/hc
  log "linked /usr/local/bin/hc -> $BIN_DIR/hc"
  if [[ -x "$BIN_DIR/herdr-core" ]]; then
    ln -sfn "$BIN_DIR/herdr-core" /usr/local/bin/herdr-core
    log "linked /usr/local/bin/herdr-core -> $BIN_DIR/herdr-core"
  fi
else
  warn "cannot write /usr/local/bin/hc; non-interactive SSH may need the absolute path"
fi

if [[ $USER_MANAGER -eq 1 ]]; then
  setup_user_manager
fi

ensure_path_block "$TARGET_HOME/.profile"
ensure_path_block "$TARGET_HOME/.bashrc"
user_shell="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f7 || true)"
case "$user_shell" in
*zsh) ensure_path_block "$TARGET_HOME/.zshrc" ;;
esac

if [[ -n $SSH_KEY ]]; then
  add_ssh_key "$SSH_KEY"
fi

if ! "$BIN_DIR/hc" --version; then
  warn "hc --version failed; check user systemd/linger before using herdr-app"
fi

check
log "done"
log "from another tailnet machine: ssh $TARGET_USER@100.72.194.36 'hc --version'"
log "then point herdr-app at that SSH target and run 'hc connect'"
