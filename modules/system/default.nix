# system-manager 模块树占位（与 modules/nixos/** 分树；禁止 import nixos 模块）。
# Phase 1：仅保证路径可 import；Phase 4 再加 T2 服务/etc。
# hostPlatform 由 outputs/.../linux-sm.nix 显式设置。
{ ... }:
{
  _file = ./default.nix;
}
