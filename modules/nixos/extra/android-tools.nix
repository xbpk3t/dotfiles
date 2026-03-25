{
  config,
  lib,
  pkgs,
  userMeta,
  ...
}: let
  cfg = config.modules.extra.android-tools.enable;
  inherit (lib) mkEnableOption mkIf;
  username = userMeta.username;
in {
  options.modules.extra.android-tools.enable =
    mkEnableOption "Android platform tools (adb/fastboot) with udev rules";

  config = mkIf cfg {
    programs.adb.enable = true;
    services.udev.packages = [pkgs.android-udev-rules];

    users.groups.adbusers = {};
    users.users."${username}".extraGroups = ["adbusers"];
  };
}
