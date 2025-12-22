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
    # https://mynixos.com/home-manager/options/services.kdeconnect
    services.kdeconnect = {
      enable = true;
      indicator = true;
      # https://mynixos.com/nixpkgs/option/programs.kdeconnect.package
      # https://github.com/GSConnect/gnome-shell-extension-gsconnect
      # KDE Connect 定义了一套协议（怎么发现设备、怎么传文件、怎么发通知等等）。GSConnect 完全兼容这套协议
      package = pkgs.gnomeExtensions.gsconnect;
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

      # 声明式启用 GNOME Shell 扩展
      # gnome-extensions list --enabled
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "clipboard-indicator@tudmotu.com"
          "dash-to-dock@micxgx.gmail.com"
          "tiling-assistant@leleat-on-github"
          "caffeine@patapon.info"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
        ];
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
