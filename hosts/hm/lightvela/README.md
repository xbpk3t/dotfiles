# hm-lightvela

Vendor-managed Vela workbench.

| Field | Value |
|---|---|
| Official machine name | `lightvela` |
| Tailnet node | `hermes-wb` |
| Tailnet IP | `100.72.194.36` |
| Substrate | systemd-nspawn container on a KVM host |
| Root filesystem | overlayfs managed by the platform |
| Persistent paths | `/root`, `/home`, `/var/lib/docker` on `/dev/vdb` |

## What we can and cannot do

- **Cannot** flash NixOS: no kexec, no writable block-device control, no boot
  control.
- **Cannot** use sm-vps/system-manager: sshd, systemd, users, and Tailscale
  belong to the platform; changes can conflict or be reset.
- **Can** install user-level Nix, `herdr-core`, and a minimal Home Manager
  profile under `$HOME`.

The machine only needs **herdr-core** (`hc`); herdr-app is the client on
Mac/phone.

## Status (2026-11-18)

- `hc 0.1.21` is installed and runs:
  `hc --version`, `hc exec echo hi`, `hc run --bg echo hi`, `hc ls`, and
  `hc server status` were verified.
- Installed from a **prebuilt closure built on `nixos-vps-dev`** and relayed
  through `nixos-vps-agt`. The `cache.numtide.com` copy of `herdr-core` is
  corrupt (a 138-byte recursive launcher, not the 9,011,784-byte ELF).
- `/root/.local/bin/hc` and `/root/.local/bin/herdr-core` are **socket-aware
  wrapper scripts** that exec the store ELF
  `/nix/store/3i34...-herdr-core-0.1.21/bin/{hc,herdr-core}`.
  `/nix` is a symlink to `/root/.nix-portable/nix`, so the ELF interpreter and
  RPATH (`/nix/store/...`) resolve without `nix-portable nix shell`.
- `/usr/local/bin/hc` and `/usr/local/bin/herdr-core` are symlinks to the
  wrappers, so plain non-interactive SSH works and herdr-app finds its remote
  binary.
- `herdr-app`'s remote command looks for **`herdr-core`**, not `hc`. Without
  the `herdr-core` name, `machine add` reports "installing herdr-core there".
  With it, `machine add` succeeds:
  `added 100.72.194.36: root@100.72.194.36 answers, hc 0.1.21`.
- The agt and Mac public keys are in `/root/.ssh/authorized_keys`.
- `libpam-systemd` is installed; the standard `user@0.service` is active,
  `Linger=yes`, and `systemctl --user` works. The earlier manual
  `systemd --user` process was stopped. This is the **hm-only** setup:
  `apt-get install libpam-systemd`, `/run/user/0`,
  `loginctl enable-linger`, and `user@0.service`. `hc server status` reports
  `keeps_running_after_logout: true`, `logout_linger_user: root`, with a live
  terminal.
- **Full HM profile is active** (`/nix/store/5dhbal...-home-manager-generation`):
  zsh 5.9.2 + starship + atuin daemon, gh (token from sops), helix, btop,
  lazygit, worktrunk, jq, ssh tailnet config; root shell is zsh. The HM profile
  intentionally does **not** own `hc`/herdr-core; the sh/closure wrappers stay
  in `/root/.local/bin` + `/usr/local/bin`.
- **Nezha agent is active** (`nezha-agent.service`) and connected to the hub
  `100.101.189.7:8008` (ESTAB on tailnet). It reads the sops-rendered
  `/root/.config/nezha/config.json`.
- `.bashrc`/`.profile` were moved to `*.pre-hm-20261118` before the first HM
  activation; HM now owns them.
- herdr-app now lists the machine as:

  ```text
  {"host":"hermes-wb","name":"100.72.194.36","state":"connected",
   "target":"root@100.72.194.36","version":"0.1.21",
   "keeps_running_after_logout":true,"logout_linger_user":"root"}
  ```

  The core/terminals now survive the app's SSH session ending. The wrappers
  choose the existing core socket: `/run/user/0/herdr-core/default.sock` if a
  user-manager core exists, else
  `/root/.local/state/herdr-core/default/default.sock`. This avoids the CLI's
  "XDG_RUNTIME_DIR or HC_SOCKET differs" error while the old core is alive.
- **Persistence:** `user@0.service` is active and `Linger=yes`, so it should
  start automatically at boot. The apt install upgraded systemd to
  `255.4-1ubuntu8.18`. A platform image reset can remove the package/unit;
  run `task nix:hm:restore` after a reset.
  `libpam-systemd` is available from the Tencent Ubuntu mirror.

## Sops (PA-only subset)

- `secrets/hm-lightvela.yaml` contains only the subset required by the host's
  imported HM modules. It is encrypted to the PA-only age key, not the fleet
  master key.
- PA private key: `/root/.config/sops/age/keys.txt`.
- `.sops.yaml` has a dedicated rule for `secrets/hm-lightvela.yaml`.
- `secrets/hm-lightvela.nix` declares only that subset and overrides
  `sops.defaultSopsFile` + `sops.age.keyFile`. It deliberately does **not**
  import `secrets/default.nix`; that would make sops-nix decrypt every fleet
  secret on the vendor-managed PA.
- The fleet master age key is **not** on the PA. If the PA is compromised, only
  that subset is exposed; rotate it and the PA age key. The other fleet secrets
  are not present in this file.

## HM activation

Default: PA-local build + activate via Ansible:

```bash
task nix:hm:apply
```

`task nix:deploy:hm` is the hm track entry: select `hm-lightvela` and the
`ansible-hm` driver runs this same playbook with an inventory generated from
`.#deployRoutes`.

`hosts/_base/hm/ansible/bootstrap.yml` tars the dotfiles tree, copies it to
`/root/hm-build` on the PA, and builds
`homeConfigurations.hm-lightvela.activationPackage` with the PA's
nix-portable. Default network: GitHub via the agt mihomo proxy, all Nix nars
from the USTC mirror / `cache.nixos.org` direct (`NO_PROXY`), measured at
~18MB/s from the PA.

Fallback: `-e hm_build_network=exitnode` uses a temporary `nixos-vps-dev`
exit node around `nix build` (all external traffic, including
`cache.nixos.org`, then goes through the exit node). It requires the tailnet
ACL grant for the PA's IP `100.72.194.36` `autogroup:internet`; with the
nftables firewall backend it also needs a forward rule for `tailscale0` on
the exit-node host, otherwise forwarded traffic is dropped by `nixos-fw`
(the iptables backend forwards by default). Tailnet SSH is unaffected by
either path.

herdr-core is intentionally not rebuilt here; it stays on the existing good
closure/wrapper path.

Fallback: prebuilt closure on a Linux builder, export, import, activate:

```bash
# build host
nix build .#homeConfigurations.hm-lightvela.activationPackage
nix-store --export $(nix-store -qR result) | gzip -9 \
  > /tmp/hm-lightvela-closure.nar.gz

# PA
gunzip -c /root/hm-lightvela-closure.nar.gz | \
  nix-portable nix-store --import

# nix-portable does not put nix-env on PATH; the HM activate script needs it.
for c in nix nix-env nix-store nix-build; do
  printf '#!/usr/bin/env bash\nexec /root/.local/bin/nix-portable %s "$@"\n' "$c" \
    > "/root/.local/bin/$c"
  chmod 0755 "/root/.local/bin/$c"
done

HOME=/root USER=root XDG_RUNTIME_DIR=/run/user/0 PATH=/root/.local/bin:$PATH \
  /nix/store/<hash>-home-manager-generation/activate

usermod -s /root/.nix-profile/bin/zsh root
```

`PATH=/root/.local/bin:$PATH` lets the activate script find the `nix-env`
wrapper. The wrapper enters nix-portable, which sees `/root` and the store.

## Nezha agent (N1)

The HM profile includes `pkgs.nezha-agent` and renders
`/root/.config/nezha/config.json` (the agent v1 expects JSON) from the sops
template. Install the system
unit once:

```bash
install -m 644 hosts/_base/hm/nezha-agent.service \
  /etc/systemd/system/nezha-agent.service
systemctl daemon-reload
systemctl enable --now nezha-agent.service
systemctl status nezha-agent.service
```

The unit waits for the sops-rendered config, then connects to the hub
`100.101.189.7:8008` (nixos-vps-dev) over tailnet.

## Restore after reboot / platform reset

**Important:** a `reboot` inside the systemd-nspawn container stops the vendor
workbench; in the 2026-11-19 test it did **not** auto-start. Start it from the
Vela/Hermes platform console first, then run the restore script if any
overlay-level state (`/nix`, `/usr/local/bin`, user@0, Nezha unit, root shell)
is missing.

Copy these two files to the PA and run the restore script as root:

```bash
scp hosts/_base/hm/restore.sh hosts/_base/hm/nezha-agent.service \
  root@100.72.194.36:/root/hm-bootstrap/
ssh root@100.72.194.36 '/root/hm-bootstrap/restore.sh'
```

It recreates `/nix`, the nix-portable command wrappers, `/usr/local/bin`
links, the user manager (`libpam-systemd` + `user@0` + linger), runs the HM
generation from `/root/.hm-generation`, sets root's shell to zsh, and installs
the Nezha system unit. The nix-portable store, HM generation, sops key, and
`hc` wrappers under `/root` are persistent and are not re-downloaded.

## herdr-app cannot add the machine

If the app says "it needs you to answer something (a password, a new host key,
or installing herdr-core there)", the usual cause is the remote binary name:

- herdr-app's remote command runs
  `p=$(command -v herdr-core) || p=$HOME/.local/bin/herdr-core; exec "$p" connect`.
- It looks for **`herdr-core`**, not `hc`. Creating only `/usr/local/bin/hc`
  is not enough.
- Confirm:
  `ssh root@100.72.194.36 'command -v herdr-core; herdr-core --version'`.
- Create both names (set `H` to the herdr-core store path first, as in Path 0:
  `H=/nix/store/<hash>-herdr-core-<version>`):
  `ln -sfn "$H/bin/hc" /root/.local/bin/hc`,
  `ln -sfn "$H/bin/herdr-core" /root/.local/bin/herdr-core`,
  `ln -sfn /root/.local/bin/hc /usr/local/bin/hc`,
  `ln -sfn /root/.local/bin/herdr-core /usr/local/bin/herdr-core`.

On the Mac, the local CLI is `/Users/luck/.local/bin/herdr-core` (`hc` is not
necessarily on PATH). Add and verify:

```bash
/Users/luck/.local/bin/herdr-core machine add root@100.72.194.36
/Users/luck/.local/bin/herdr-core machine ls
```

A successful add prints
`added 100.72.194.36: root@100.72.194.36 answers, hc 0.1.21`.
Tailscale ping being fast does not prove this step is fine.

## User

The platform currently authorizes `root` (`hermes-workbench-client`). We do
not create `luck`. The Home Manager profile targets `root`; if you switch to
`desk`, change `home.username` and `home.homeDirectory` in `home.nix`.

## Path 0: prebuilt closure (proven; use this for CN PAs)

Use this when the PA cannot reach GitHub or when `cache.numtide.com` serves a
bad `herdr-core`.

### Build / export on `nixos-vps-dev`

```bash
STORE=/nix/store/3i34drh7c06blwgasbg43q7misp1f1c5-herdr-core-0.1.21
nix-store --export $(nix-store -qR "$STORE") | gzip -9 \
  > /tmp/herdr-core-closure.nar.gz
```

Verify the source is a real ELF first:

```bash
stat -c '%s' "$STORE/bin/herdr-core"   # 9011784
sha256sum "$STORE/bin/herdr-core"      # 12edb914...
```

`nixos-vps-dev` already has this good store path. `nixos-vps-agt` has the same
closure and can act as a same-region relay.

### Relay to the PA

```bash
scp /tmp/herdr-core-closure.nar.gz root@100.72.194.36:/root/
```

### Import on the PA

If the PA already has the corrupt `3i34...` path, remove the profile entry,
old generations, and stale GC roots first:

```bash
nix-portable nix profile remove herdr-core
nix-portable nix-env --profile /nix/var/nix/profiles/per-user/root/profile \
  --delete-generations old
rm -f /tmp/hc-result
nix-portable nix-store --delete /nix/store/3i34drh7c06blwgasbg43q7misp1f1c5-herdr-core-0.1.21
```

`nix-store --import` expects an **uncompressed** NAR:

```bash
gunzip -c /root/herdr-core-closure.nar.gz | nix-portable nix-store --import
```

Then expose the store and link `hc`:

```bash
[ -e /nix ] || ln -s /root/.nix-portable/nix /nix
H=/nix/store/3i34drh7c06blwgasbg43q7misp1f1c5-herdr-core-0.1.21
ln -sfn "$H/bin/hc" /root/.local/bin/hc
ln -sfn "$H/bin/herdr-core" /root/.local/bin/herdr-core
ln -sfn /root/.local/bin/hc /usr/local/bin/hc
ln -sfn /root/.local/bin/herdr-core /usr/local/bin/herdr-core
hc --version
herdr-core --version
```

On this PA a manual `systemd --user` was later started, so the actual
`/root/.local/bin/{hc,herdr-core}` are **socket-aware wrapper scripts** (see
Status). `hosts/_base/hm/bootstrap.sh` now writes the same wrappers. The plain
symlinks above are the no-user-manager case.

Do **not** use `nix-portable nix shell` for `hc` here. It can re-substitute the
bad cache output and hang/recurse. Run the store ELF directly (the `/nix`
symlink makes it work).

## Path 1: sh bootstrap (GitHub-capable hosts)

Run as the target user (`root` here):

```bash
./hosts/_base/hm/bootstrap.sh --check
./hosts/_base/hm/bootstrap.sh
./hosts/_base/hm/bootstrap.sh --ssh-key ~/.ssh/id_ed25519.pub
# hm-only: install libpam-systemd, enable linger, start user@0.service
./hosts/_base/hm/bootstrap.sh --user-manager
```

The script uses system Nix if present, otherwise `nix-portable`; installs
`herdr-core` with `nix profile`; writes `~/.config/herdr-core/config.toml`;
creates the `/nix` symlink when needed; writes socket-aware
`~/.local/bin/{hc,herdr-core}` wrappers; and reports user-systemd/linger
status. `--user-manager` is **hm-only** (it installs `libpam-systemd` and
touches systemd/linger); do not use it for NixOS or sm-vps hosts. The script's
normal path never touches `/etc`, sshd, Tailscale, or sops.

This path assumes GitHub and a usable cache. For a China PA, use Path 0.

## Path 2: declarative Home Manager

The node exposes only:

```text
homeConfigurations.hm-lightvela
```

Once Nix and Home Manager are available on the machine (and the flake is
present locally or referenced remotely):

```bash
home-manager switch --flake .#hm-lightvela
```

The host imports `home/hm` plus the selected `home/base` modules; the exact
list lives in `hosts/hm/<node>/home.nix`. The host must import
`secrets/hm-<node>.nix`; the GUI-heavy `home/base` modules are not imported
wholesale.
This path is not applied yet on this PA; the sh/closure path is the current
installation.

## Verification

```bash
hc --version
herdr-core --version
hc exec echo hi
hc server status
ssh root@100.72.194.36 'hc --version'
ssh root@100.72.194.36 'herdr-core --version'
systemctl --user status
loginctl show-user root -p Linger
```

On the Mac, add/verify the machine with the local `herdr-core` CLI as described
in [herdr-app cannot add the machine](#herdr-app-cannot-add-the-machine).

`hc server status` should report `keeps_running_after_logout: true` with
`logout_linger_user: root` (see Status); `hc exec`/`hc run` use the
user-manager core.

## Persistence

- `/root`, `/home`, and `/var/lib/docker` are on `/dev/vdb` and survive a
  platform image reset.
- `/nix` is a symlink on the overlay. If the platform resets `/`, recreate it:
  `ln -s /root/.nix-portable/nix /nix`.
- `/usr/local/bin/hc` is also on the overlay; recreate it after a reset:
  `ln -sfn /root/.local/bin/hc /usr/local/bin/hc`.
- The nix-portable store and the imported closure live under `/root`, so they
  survive a reset; the `/nix` symlink, `/root/.local/bin/hc`, and
  `/usr/local/bin/hc` are the pieces to re-check/recreate.
