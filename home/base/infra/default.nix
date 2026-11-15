{
  mylib,
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.infra.basePackages;
in
{
  options.modules.infra.basePackages.enable =
    lib.mkEnableOption "base CLI (openssh / openssl / age / sops)";

  imports = mylib.scanPaths ./.;

  config.home.packages = lib.optionals cfg.enable (
    with pkgs;
    [
      openssh
      openssl
      age
      sops
    ]
  );
}
