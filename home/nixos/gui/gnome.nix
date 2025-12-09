{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.gnome or {enable = false;};
in {
  options.modules.desktop.gnome = {
    enable = lib.mkEnableOption "Home-layer tweaks for GNOME session";
  };

  config = lib.mkIf cfg.enable {
    # GNOME 常用工具与扩展
    home.packages = with pkgs; [
      gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.clipboard-indicator
    ];

    # 确保使用 GNOME portal，避免与其它 compositor 配置冲突
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gnome];
      config.common.default = ["gnome" "gtk"];
    };
  };
}
