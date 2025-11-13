{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.modules.desktop.niri;
  xwaylandDisplay = ":0";
  waylandSocket = "wayland-1";
in {
  options.modules.desktop.niri = {
    enable = lib.mkEnableOption "niri compositor";
  };

  imports = [
    inputs.niri.homeModules.niri
  ];

  config = lib.mkIf cfg.enable {
    # 安装 xwayland-satellite 以支持 X11 应用（如 GoLand）
    home.packages = with pkgs; [
      niri

      xwayland-satellite

      # https://github.com/psi4j/sunsetr
      sunsetr

      # https://github.com/atx/wtype
      wtype

      # nirius
    ];

    # Wayland 环境变量
    # 确保应用正确使用 Wayland 和 compositor 的缩放设置
    home.sessionVariables = {
      # 禁用 GDK 的 DPI 缩放，让 compositor 处理
      GDK_DPI_SCALE = "1.0";
      # 确保 Qt 应用使用 Wayland
      QT_QPA_PLATFORM = "wayland";
      # 给 X11 应用一个稳定的 DISPLAY，配合 xwayland-satellite systemd 服务
      DISPLAY = xwaylandDisplay;
    };

    # MAYBE [2025-10-17] [Gesture bindings · Issue #372 · YaLTeR/niri](https://github.com/YaLTeR/niri/issues/372) 等niri支持自定义gestures之后，修改配置

    # https://mynixos.com/home-manager/options/services.mako
    # notify-send
    #　Mako is a lightweight notification daemon specifically designed for Wayland compositors. It doesn't require a full desktop environment (like GNOME or KDE) to function. Instead, it can run in minimal setups as long as you have:
    #
    #A Wayland compositor (e.g., Sway, Hyprland, or River) installed and running.
    #D-Bus support (for handling notifications).
    #Basic dependencies like Wayland libraries, Pango, Cairo, and optionally GDK-Pixbuf for icons.
    #
    #In a minimal distro (such as a base Arch Linux or Alpine install without a DE), you can use Mako by installing these prerequisites and configuring it via tools like Home Manager in Nix. It won't work in a purely text-based (CLI-only) environment, since it's graphical and relies on Wayland for rendering notifications.
    services.mako = {
      enable = true;
      #      backgroundColor = "#1e1e2e";
      #      textColor = "#cdd6f4";
      #      borderColor = "#89b4fa";
      #      borderRadius = 8;

      settings = {
        #      anchor = "top-right";

        "actionable=true" = {
          anchor = "top-left";
        };
        actions = true;
        anchor = "top-right";
        icons = true;
        ignore-timeout = false;
        markup = true;

        default-timeout = 3000;
        #      ignore-timeout = 1;

        # keep notifications visible even for fullscreen windows
        # 保证在fullscreen模式下，也能看到弹窗
        layer = "overlay";
        #              "mode=${mode}".invisible = 1;
        "app-name=Countdown" = {
          width = 60;
          height = 24;
          margin = 4;
          padding = 4;
          border-size = 0;
          markup = true;
          icons = false;
          default-timeout = 0;
          ignore-timeout = true;
          format = "<span font='Sans 10' weight='bold'>%s</span>";
          text-alignment = "center";
          font = "Sans 8";
        };
      };
    };

    # Niri compositor 配置
    # 使用 KDL 配置文件
    programs.niri = {
      enable = true;
      package = pkgs.niri;

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

    # Wrap the upstream niri-session launcher so greetd exports DISPLAY before
    # systemd --user captures the environment. Anything spawned from the
    # compositor (terminals, launchers, JetBrains IDEs, etc.) now inherits the
    # same DISPLAY value without manual exports.
    home.file.".wayland-session" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        export WAYLAND_DISPLAY=${waylandSocket}
        export DISPLAY=${xwaylandDisplay}
        exec ${config.programs.niri.package}/bin/niri-session "$@"
      '';
    };

    home.file.".config/sunset/sunsetr.toml".source = config.lib.file.mkOutOfStoreSymlink "./sunsetr.toml";

    systemd.user.services."xwayland-satellite" = {
      Unit = {
        Description = "Xwayland bridge for X11 apps under niri";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
        Environment = [
          "WAYLAND_DISPLAY=${waylandSocket}"
          "DISPLAY=${xwaylandDisplay}"
        ];
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
