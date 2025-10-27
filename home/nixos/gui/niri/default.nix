{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.niri;
in {
  options.modules.desktop.niri = {
    enable = lib.mkEnableOption "niri compositor";
  };

  config = lib.mkIf cfg.enable {
    # 安装 xwayland-satellite 以支持 X11 应用（如 GoLand）
    home.packages = with pkgs; [
      xwayland-satellite

      # https://github.com/psi4j/sunsetr
      sunsetr

      # https://github.com/atx/wtype
      wtype

      nirius
    ];

    # Wayland 环境变量
    # 确保应用正确使用 Wayland 和 compositor 的缩放设置
    home.sessionVariables = {
      # 禁用 GDK 的 DPI 缩放，让 compositor 处理
      GDK_DPI_SCALE = "1.0";
      # 确保 Qt 应用使用 Wayland
      QT_QPA_PLATFORM = "wayland";
    };

    # MAYBE [2025-10-17] [Gesture bindings · Issue #372 · YaLTeR/niri](https://github.com/YaLTeR/niri/issues/372) 等niri支持自定义gestures之后，修改配置

    # Niri compositor 配置
    # 使用 KDL 配置文件
    programs.niri = {
      enable = true;

      # 使用 KDL 配置文件
      # 参考: https://github.com/cap153/config/blob/main/niri/.config/niri/config.kdl
      config = builtins.readFile ./config.kdl;
    };

    # XDG Portal 配置
    xdg.portal = {
      enable = true;

      config = {
        common = {
          # 使用 xdg-desktop-portal-gtk 和 niri 的 portal
          default = [
            "gtk"
            "gnome"
          ];
          # gnome-keyring 处理密钥门户
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
        };

        # niri 特定配置
        niri = {
          default = [
            "gtk"
            "gnome"
          ];
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
        };
      };

      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
    };

    # NOTE: this executable is used by greetd to start a wayland session when system boot up
    # with such a vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS module
    home.file.".wayland-session" = {
      source = "${config.programs.niri.package}/bin/niri-session";
      executable = true;
    };

    home.file.".config/sunset/sunsetr.toml".source = config.lib.file.mkOutOfStoreSymlink "./sunsetr.toml";
  };
}
