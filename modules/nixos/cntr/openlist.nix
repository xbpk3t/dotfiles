{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.openlist;
  containerName = "openlist";
  stateDir = "/var/lib/${containerName}";
in {
  # Ensure the `./data` directory is writable by UID 1001 (the user that runs the container):
  #   mkdir -p data
  #   sudo chown -R 1001:1001 data

  options.modules.services.openlist = {
    enable = mkEnableOption "OpenList (container)";

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "OpenList");
      default = null;
      description = "Expose OpenList via the shared reverse proxy.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra container attributes.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${stateDir} 0750 root root -"
      ];

      virtualisation.oci-containers.containers.${containerName} = mkMerge [
        {
          autoStart = false;
          image = "openlistteam/openlist:latest";
          volumes = [
            "${stateDir}:/opt/openlist/data:rw"
            #            "/home/luck/Desktop/dotfiles/manifests/docker/openlist/data:/opt/openlist/data:rw"
            #            "/home/luck/Downloads:/home/luck/Downloads:ro"
            #            "/home/luck/Downloads/vscs-video:/home/luck/Downloads/vscs-video:ro"
          ];
          ports = [
            "5244:5244/tcp"
          ];
          log-driver = "journald";
          #          extraOptions = [
          #            "--network-alias=openlist"
          #            "--network=openlist_default"
          #          ];
        }
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.openlist";
        ingress = cfg.ingress;
      })
    )
  ];
}
