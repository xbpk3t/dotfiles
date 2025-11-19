{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.services.watchtower;
  containerName = "watchtower";
in {
  options.modules.services.watchtower = {
    enable = mkEnableOption "Watchtower auto-updater (container)";

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra container attributes.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.${containerName} = mkMerge [
      {
        autoStart = false;
        image = "containrrr/watchtower:latest";
        environment = {
          TZ = "Asia/Shanghai";
          WATCHTOWER_CLEANUP = "true";
        };
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:rw"
        ];
        cmd = ["--interval" "3600" "--cleanup"];
        log-driver = "journald";
        extraOptions = [
          #            "--network-alias=watchtower"
          #            "--network=watchtower_default"
        ];
      }
      cfg.settings
    ];
  };
}
