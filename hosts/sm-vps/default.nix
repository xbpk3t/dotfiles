# sm-vps 角色：非 NixOS 系统态声明（sm 轨的「装配清单」）。
# 与 nixos 轨 hosts/<role>/default.nix 对齐——但 sm 是非 NixOS，无 NixOS module
# 语义，这里声明「该角色启用的 sm 模块开关」（modules.sm.<cap>.enable），
# 由 outputs/x86_64-linux/src/sm-vps.nix 装配。
{ lib, ... }:
{
  # 各 sm 能力开关（modules.sm.<cap>.enable，定义在 modules/sm/default.nix）
  modules.sm = {
    # systemd 配置（journald/logind）
    systemd.enable = true;
    # i18n（locale/timezone）
    i18n.enable = true;
    # sshd 硬化（environment.etc drop-in）
    sshd.enable = true;
    # tailscale 说明（官方脚本管理）
    tailscale.enable = true;
    # 系统 sops（root secrets 解密）
    sops.enable = true;
    # mihomo 代理客户端（完整复用 client-config.nix）
    mihomo.enable = true;
  };
}
