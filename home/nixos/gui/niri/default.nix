{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.niri;

  # 读取 KDL 配置文件并替换 stylix 图片路径
  configKdl = builtins.readFile ./config.kdl;
  # 替换 @STYLIX_IMAGE@ 占位符为实际的 stylix 图片路径
  finalConfigKdl =
    builtins.replaceStrings
    ["@STYLIX_IMAGE@"]
    ["${config.stylix.image}"]
    configKdl;
in {
  options.modules.desktop.niri = {
    enable = lib.mkEnableOption "niri compositor";
  };

  config = lib.mkIf cfg.enable {
    # 安装 xwayland-satellite 以支持 X11 应用（如 GoLand）
    home.packages = with pkgs; [
      xwayland-satellite
    ];

    # FIXME [2025-10-17] [Gesture bindings · Issue #372 · YaLTeR/niri](https://github.com/YaLTeR/niri/issues/372) 等niri支持自定义gestures之后，修改配置

    # Niri compositor 配置
    # 使用 KDL 配置文件
    programs.niri = {
      enable = true;

      # 使用 KDL 配置文件
      # 参考: https://github.com/cap153/config/blob/main/niri/.config/niri/config.kdl
      config = finalConfigKdl;
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
  };
}
