{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.infra.android-tools.enable;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.infra.android-tools.enable = mkEnableOption "Android platform tools (adb/fastboot)";

  config = mkIf cfg {
    # nixpkgs 26.11 起：
    #   - `android-udev-rules` 已移除（由 systemd 内置 uaccess rules 取代，
    #     见 rl-2511 release notes）；
    #   - `programs.adb` 也不再提供。
    # 因此系统侧只需要安装 android-tools；USB 设备权限交给 systemd uaccess。
    environment.systemPackages = [ pkgs.android-tools ];
  };
}
