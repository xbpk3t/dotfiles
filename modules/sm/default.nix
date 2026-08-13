# sm 轨 system-manager 模块树（与 modules/nixos/** 分树；禁止 import nixos 模块）。
# 命名对齐：modules/{nixos,darwin,sm} 三轨平台，sm = 非 NixOS Linux 的系统管理面。
# 组织：按能力分文件；每个能力在自己的文件里声明 modules.sm.<cap>.enable 开关
# （默认 false，由 hosts/sm-vps/default.nix 装配清单开启）。
# hostPlatform / allowAnyDistro 由 outputs/.../sm-vps.nix 显式设置。
{ ... }:
{
  _file = ./default.nix;

  imports = [
    ./packages.nix
    ./managed-flag.nix
    ./sshd.nix
    ./nix-conf.nix
    ./tailscale.nix
    ./sops.nix
    ./systemd.nix
    ./i18n.nix
    ./mihomo.nix
  ];
}
