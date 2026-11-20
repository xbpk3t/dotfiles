# hm Ansible

Target-only Ansible for vendor-managed `kind = "home"` PAs.

The PA builds its own HM generation with `nix-portable`; Ansible does not build
on dev/agt and does not transfer a 778MB closure.

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
task nix:hm:apply
# or:
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
