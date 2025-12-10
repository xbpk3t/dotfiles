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
      gnomeExtensions.dash-to-dock
      gnomeExtensions.tiling-assistant
      gnomeExtensions.caffeine
    ];

    # 输入法与 Wayland 环境（仅 GNOME 会话下生效，避免污染其他会话）
    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };

    # XDG portal 只保留 GNOME/GTK，避免与其他 compositor portal 冲突
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gnome];
      config.common.default = ["gnome" "gtk"];
    };

    # GNOME 体验调优（通过 dconf，集中常用手感项）
    dconf.settings = {
      # 键盘：Caps 变 Ctrl，保留其他布局选项
      "org/gnome/desktop/input-sources" = {
        xkb-options = ["caps:ctrl_modifier"];
      };

      # 触控板：轻触和自然滚动
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
        natural-scroll = true;
      };

      # 分数缩放试验特性（必要时可关）
      "org/gnome/mutter" = {
        experimental-features = ["scale-monitor-framebuffer"];
      };

      # 夜灯：22:00–07:00，3800K
      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-from = 22.0;
        night-light-schedule-to = 7.0;
        night-light-temperature = 3800;
      };

      # 电源：插电 60 分钟后休眠（按需调整）
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-timeout = 3600;
      };

      # Dock：底部、自动隐藏、非固定宽度
      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-fixed = false;
        dock-position = "BOTTOM";
        intellihide = true;
      };
    };
  };
}
