{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.hyprland;
  hyprlandPkg = pkgs.hyprland;
  xwaylandDisplay = ":0";
  waylandSocket = "wayland-1";
  enableSatellite = cfg.enableXwaylandSatellite;
in {
  options.modules.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland compositor";
    enableXwaylandSatellite = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run xwayland-satellite user service (for fixed DISPLAY); Hyprland itself already embeds Xwayland.";
    };
  };

  imports = [
    ./xdg.nix
  ];

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        hyprlandPkg
        wtype
        sunsetr
      ]
      ++ lib.optionals enableSatellite [xwayland-satellite];

    # Wayland / X11 related environment
    home.sessionVariables =
      {
        GDK_DPI_SCALE = "1.0";
        QT_QPA_PLATFORM = "wayland";
      }
      // lib.optionalAttrs enableSatellite {
        DISPLAY = xwaylandDisplay;
        WAYLAND_DISPLAY = waylandSocket;
      };

    # Notifications
    services.mako = {
      enable = true;
      settings = {
        actions = true;
        anchor = "top-right";
        icons = true;
        markup = true;
        default-timeout = 3000;
        layer = "overlay";
        "actionable=true" = {anchor = "top-left";};
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

    wayland.windowManager.hyprland = {
      enable = true;
      package = hyprlandPkg;
      extraConfig = builtins.readFile ./config.conf;
    };

    # Wrap Hyprland session for greetd/DM
    home.file.".wayland-session" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        ${lib.optionalString enableSatellite ''
          export WAYLAND_DISPLAY=${waylandSocket}
          export DISPLAY=${xwaylandDisplay}
        ''}
        exec ${hyprlandPkg}/bin/Hyprland "$@"
      '';
    };

    # Optional xwayland-satellite user service (mirrors Niri setup)
    systemd.user.services."xwayland-satellite" = lib.mkIf enableSatellite {
      Unit = {
        Description = "Xwayland bridge for X11 apps under Hyprland";
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

    # Sunsetr config symlink
    home.file.".config/sunset/sunsetr.toml".source = config.lib.file.mkOutOfStoreSymlink "./sunsetr.toml";
  };
}
