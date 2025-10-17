{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.desktop.shell;
in {

  options.modules.desktop.shell = {
    noctalia = {
      enable = mkEnableOption "noctalia shell systemd service";

      target = mkOption {
        type = types.str;
        #        default = "graphical-session.target";
        default = "hyprland-session.target";
        description = "Systemd target for noctalia shell service";
      };
    };
  };

  config = mkMerge [
    #---------------------------------------------------------------------------
    # NOCTALIA CONFIGURATION
    #---------------------------------------------------------------------------
    (mkIf cfg.noctalia.enable {
      # Noctalia shell service
      # 注意：需要 target，否则需要手动启动
      services.noctalia-shell = {
        enable = true;
        target = cfg.noctalia.target;
      };
    })
  ];
}
