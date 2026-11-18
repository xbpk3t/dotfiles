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
  default.nix     # shared, identity-agnostic, sops-free HM profile

hosts/_base/hm/
  bootstrap.sh    # user-level Nix/herdr-core installer (not a system bootstrap)
  herdr-core.toml
```

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

## Why not `hosts/sm-vps/ansible`?

`hosts/sm-vps/ansible` is a **system bootstrap** for a real Debian/Ubuntu VM
that we control through root: it creates `luck`, installs system Nix, pushes
the fleet age key, manages Tailscale, and hardens sshd. On a vendor PA those
assumptions are wrong and the sshd/Tailscale steps can lock us out. The `hm`
group therefore uses a separate, user-level bootstrap. Do not reuse or move
the sm-vps playbook.
