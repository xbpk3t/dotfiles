{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.infra.android;
in
{
  options.modules.infra.android.enable =
    lib.mkEnableOption "Android tools (fdroidcl / android-tools / scrcpy)";

  config.home.packages = lib.optionals cfg.enable (
    with pkgs;
    [
      fdroidcl
      android-tools
      scrcpy
    ]
  );
}
