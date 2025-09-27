{
  pkgs,
  config,
  lib,
  niri,
  ...
}: let
  cfg = config.modules.desktop.niri;
in {
  options.modules.desktop.niri = {
    enable = lib.mkEnableOption "niri compositor";
    settings = lib.mkOption {
      type = with lib.types; let
        valueType =
          nullOr (oneOf [
            bool
            int
            float
            str
            path
            (attrsOf valueType)
            (listOf valueType)
          ])
          // {
            description = "niri configuration value";
          };
      in
        valueType;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = with pkgs; [
          # Niri v25.08 will create X11 sockets on disk, export $DISPLAY, and spawn `xwayland-satellite` on-demand when an X11 client connects
          xwayland-satellite
        ];

        # NOTE: this executable is used by greetd to start a wayland session when system boot up
        # with such a vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS module
        home.file.".wayland-session" = {
          source = pkgs.writeScript "init-session" ''
            # trying to stop a previous niri session
            systemctl --user is-active niri.service && systemctl --user stop niri.service
            # and then we start a new one
            /run/current-system/sw/bin/niri-session
          '';
          executable = true;
        };
      }
      {
        # Merge all niri configuration parts
        xdg.configFile."niri/config.kdl".text = let
          settingsConfig = import ./settings.nix niri;
          keybindingsConfig = import ./keybindings.nix niri;
          spawnConfig = import ./spawn-at-startup.nix niri;
          windowrulesConfig = import ./windowrules.nix niri;
          allConfigs = settingsConfig ++ keybindingsConfig ++ spawnConfig ++ windowrulesConfig ++ cfg.settings;
        in
          niri.lib.kdl.render allConfigs;
      }
    ]
  );
}
