# hosts/hm

`hm` is the **home-manager-only** group for machines whose OS we do not
control: vendor-provided PA workbenches, managed containers, and similar
substrates.

A node here:

- has `kind = "home"` in `meta.nix`;
- produces only `homeConfigurations.<node>`;
- produces no `nixosConfigurations`, no `systemConfigs`, and no
  `deploy.nodes`;
- is activated with `home-manager switch --flake .#<node>` (or the shared
  `hosts/_base/hm/bootstrap.sh` for a minimal `nix profile` flow).

It is still a first-class `task nix:deploy:hm` target: the fleet registry
derives `deploy.driver = "ansible-hm"` for every `kind = "home"` node, and
the hm track routes it to the Ansible playbook below. `deploy.nodes` is
not generated because the PA has no remote Nix daemon/store for deploy-rs.

Node naming follows the fleet path convention:

```text
hosts/hm/lightvela  ->  hm-lightvela
hosts/hm/<machine>  ->  hm-<machine>
```

## Layout

```text
hosts/hm/
  lightvela/
    meta.nix      # kind = "home"; system; stateVersion; tailscale.ip
    home.nix      # per-machine identity + imports home/hm
    README.md     # machine-specific constraints

home/hm/
  default.nix     # shared, identity-agnostic HM profile (consumes a few
                  # sops secrets; host imports secrets/hm-<node>.nix)

hosts/_base/hm/
  bootstrap.sh    # user-level Nix/herdr-core installer (not a system bootstrap)
  herdr-core.toml
```

## Adding a new hm node

Create `hosts/hm/<name>/{meta.nix,home.nix,README.md}` with `kind = "home"`,
`system`, `stateVersion`, `tailscale.ip`, and `ssh.user`. No Taskfile or
Ansible inventory edit is needed:

- `lib/fleet` derives `deployDriver = "ansible-hm"` from `kind = "home"`;
- the node appears in `task nix:deploy:hm` via `.#deployRoutes`;
- the Ansible inventory is generated from the same route facts.

If the node needs a different mechanism, set `deploy.driver` explicitly in
`meta.nix`; the current Taskfile handles `deploy-rs` and `ansible-hm`.

## Prebuilt closures

For a PA that cannot reach GitHub or receives a corrupt cache output, build the
closure on `nixos-vps-dev`, relay it through `nixos-vps-agt`, and import it on
the PA. The exact commands and the `/nix` symlink requirement are documented
in `hosts/hm/lightvela/README.md` (Path 0).

## User manager (hm-only)

`hosts/_base/hm/bootstrap.sh --user-manager` installs `libpam-systemd`, creates
`/run/user/<uid>`, enables linger, and starts `user@<uid>.service`. This makes
`keeps_running_after_logout` true for herdr-app. It is intentionally **hm-only**
(vendor PAs); do not apply it to NixOS or sm-vps hosts. It is a system-level
change and can be removed by a platform image reset; re-run it after a reset.

## Build / apply (hm-only)

The default is a PA-local build via Ansible:

```bash
task nix:hm:apply
```

`task nix:deploy:hm` is the hm track entry: it lists every
`ansible-hm` node in `.#deployRoutes`, supports multi-select, and calls
`task nix:hm:apply NODES=...`. Both commands generate the Ansible inventory
from `deployRoutes` (`host`/`sshUser` from `meta.nix`); the static
`hosts/_base/hm/ansible/inventory/hm.ini` is only an optional manual
override (`INVENTORY=...`).

It builds `homeConfigurations.<node>` on the PA with nix-portable, then
activates. Default network: GitHub via the agt mihomo proxy, Nix nars from
the USTC mirror direct; no dev-built 778MB closure transfer. The
`exitnode` fallback sets a temporary `nixos-vps-dev` exit node only around
`nix build` and clears it in an `always` block; it requires the tailnet ACL
grant for the PA's IP `100.72.194.36` `autogroup:internet` and, when the
firewall backend is nftables, a forward rule for `tailscale0` on the
exit-node host (handled by `modules/nixos/infra/tailscale-client.nix`; the
iptables backend forwards by default).
`herdr-core` remains on its separate good-closure path.
`task nix:hm:restore` is the platform-reset recovery.

## Why not `hosts/sm-vps/ansible`?

`hosts/sm-vps/ansible` is a **system bootstrap** for a real Debian/Ubuntu VM
that we control through root: it creates `luck`, installs system Nix, pushes
the fleet age key, manages Tailscale, and hardens sshd. On a vendor PA those
assumptions are wrong and the sshd/Tailscale steps can lock us out. The `hm`
group therefore uses a separate, user-level bootstrap. Do not reuse or move
the sm-vps playbook.
