# hm Ansible

Target-only Ansible for vendor-managed `kind = "home"` PAs.

The PA builds its own HM generation with `nix-portable`; Ansible does not build
on dev/agt and does not transfer a 778MB closure. The playbook requires
`/root/.local/bin/nix-portable` and creates the four `nix*` command wrappers
itself, so a PA bootstrapped with `bootstrap.sh` does not need the manual Path 0
wrapper step. It does not support a system-Nix-only PA.

Network (default, `hm_build_network=proxy`): GitHub goes through the agt
mihomo proxy (`http://100.66.22.92:7890`); all Nix nars come from the USTC
mirror (`https://mirrors.ustc.edu.cn/nix-channels/store`) and
`cache.nixos.org`, both direct via `NO_PROXY`. Measured on the PA: USTC
~18MB/s, while the exit-node tunnel was ~15-22KB/s.

Fallback: `-e hm_build_network=exitnode` sets a temporary nixos-vps-dev exit
node only around `nix build` and clears it in an `always` block. Tailnet SSH
is unaffected (Tailscale routes `100.64.0.0/10` more specifically than the
exit-node default route). The ACL must grant the PA's tailnet IP
`100.72.194.36` `autogroup:internet`; see
`infra/stacks/homelab/tailscale/tailnet/terranix.nix` and apply with
`task tf:terranix-tailscale` + `task tf:plan` / `task tf:apply`.
(`user@hostname` is not a valid ACL `src`; use the IP or a tag.) With the
nftables firewall backend the exit node also needs forwarding from
`tailscale0`: `modules/nixos/infra/tailscale-client.nix` adds
`networking.firewall.extraForwardRules = ''iifname "tailscale0" accept''`
when `exitNode` is enabled and the backend is nftables. The iptables backend
does not filter FORWARD, so no extra rule is needed there.

## Usage

From the repo root (Mac or agt; both have ansible + SSH to the PA):

```bash
task nix:deploy:hm               # hm track: multi-select ansible-hm nodes
task nix:hm:apply                # hm-only: all ansible-hm nodes
task nix:hm:apply NODES=hm-lightvela
```

The inventory is generated from flake `.#deployRoutes` (`host`/`sshUser` from
`hosts/hm/<node>/meta.nix`), so a new `hosts/hm/<name>/` node needs no
inventory edit. `inventory/hm.ini` is only a manual override
(`INVENTORY=...`); the raw command still works:

```bash
ansible-playbook -i hosts/_base/hm/ansible/inventory/hm.ini \
  hosts/_base/hm/ansible/bootstrap.yml
```

The build source is the current dotfiles tree (`hm_source` in
`group_vars/hm.yml`). The source is tarred on the control node, copied to
`/root/hm-build` on the PA, built there, and activated.

Recovery after a platform image reset:

```bash
task nix:hm:restore
# or: ansible-playbook ... --tags restore
```

This copies `restore.sh` + `nezha-agent.service` to `/root/hm-bootstrap` and
runs the restore script. The platform must have started the workbench first;
`reboot` inside the systemd-nspawn container does not auto-start it.

## Scope

- hm-only; do not point this at NixOS or sm-vps hosts.
- `libpam-systemd`/`user@0` is the same hm-only system-level change as
  `bootstrap.sh --user-manager`.
- `herdr-core` remains on its existing closure/wrapper path; this playbook does
  not rebuild herdr-core.
