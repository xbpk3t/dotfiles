# system-manager 模块树（与 modules/nixos/** 分树；禁止 import nixos 模块）。
# Phase 4 T2：最小声明 + 可验证的系统态（etc flag + 可选 oneshot）。
# hostPlatform / allowAnyDistro 由 outputs/.../sm-vps.nix 显式设置。
{ ... }:
{
  _file = ./default.nix;

  imports = [
    ./packages.nix
    ./managed-flag.nix
  ];
}
