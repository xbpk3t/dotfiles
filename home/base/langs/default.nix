{
  mylib,
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.langs.basePackages;
in
{
  options.modules.langs.basePackages.enable =
    lib.mkEnableOption "base language toolchain (gcc / cmake / lua / miller)";

  imports = mylib.scanPaths ./.;

  config.home.packages = lib.optionals cfg.enable (
    with pkgs;
    [
      gcc

      cmake
    ]
    ++ [
      lua
      # stylua config: managed by treefmt (home/base/langs/treefmt.nix)
      stylua
    ]
    ++ [
      miller
    ]
  );
}
