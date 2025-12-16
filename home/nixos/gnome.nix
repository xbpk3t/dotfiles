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
      # 顶栏托盘图标（AppIndicator 支持）
      gnomeExtensions.appindicator

      # https://mynixos.com/nixpkgs/package/gnomeExtensions.clipboard-indicator
      gnomeExtensions.clipboard-indicator
      # 将 Dash 变为 Dock，可自定义位置/自动隐藏
      # https://github.com/micheleg/dash-to-dock
      gnomeExtensions.dash-to-dock
      # 窗口平铺/网格助手
      gnomeExtensions.tiling-assistant
      # 顶栏防休眠/防锁屏开关
      gnomeExtensions.caffeine

      # 键盘重映射工具及配置
      # https://mynixos.com/nixpkgs/package/xremap
      # xremap
      # xremap GNOME 扩展（Wayland 前台窗口名称查询）
      # https://mynixos.com/nixpkgs/package/gnomeExtensions.xremap
      # gnomeExtensions.xremap
      # gnome-macos-remap-wayland
    ];

    # 输入法与 Wayland 环境（仅 GNOME 会话下生效，避免污染其他会话）
    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      # 强制 Firefox/GTK 使用原生 Wayland，避免 XWayland 下缩放偏差
      MOZ_ENABLE_WAYLAND = "1";
      # JetBrains IDE（含 GoLand）启用 Wayland 渲染；新版本默认支持，老版本需此开关
      JBR_ENABLE_WAYLAND = "1";
      # 让 Firefox 默认 125% UI 缩放，匹配你原先 1.25~1.5 的体验
      # MOZ_CONFIG_DEVPIXELS_PER_PX = "1.25";
    };

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
