# sm 轨 system-manager 模块树（与 modules/nixos/** 分树；禁止 import nixos 模块）。
# 命名对齐：modules/{nixos,darwin,sm} 三轨平台，sm = 非 NixOS Linux 的系统管理面。
# 组织：按能力分文件，S2 白名单加厚时逐文件填充（对齐 modules/nixos 的可裁剪风格）。
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
  ];
}
