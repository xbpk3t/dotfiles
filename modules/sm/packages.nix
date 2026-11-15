# 最小 systemPackages：证明 sm 能收敛可执行路径，体积可控。
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.sm.packages;
in
{
  _file = ./packages.nix;

  options.modules.sm.packages.enable = lib.mkEnableOption "sm baseline packages";

  config.environment.systemPackages = lib.optionals cfg.enable [
    pkgs.hello
  ];
}
