{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.beszel;
  containerName = "beszel";
  stateDir = "/var/lib/${containerName}";
in {
  options.modules.services.beszel = {
    enable = mkEnableOption "Beszel monitoring hub (container)";

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "Beszel");
      default = null;
      description = "Expose Beszel through the shared reverse proxy.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra attributes merged into the OCI container definition.";
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
          image = "henrygd/beszel:latest";
          environment = {
            TZ = "Asia/Shanghai";
          };
          volumes = [
            "${stateDir}:/beszel_data:rw"
            #            "/home/luck/Desktop/dotfiles/manifests/docker/beszel/beszel_data:/beszel_data:rw"
          ];
          ports = [
            "8090:8090/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            #            "--add-host=host.docker.internal:host-gateway"
            #            "--network-alias=beszel"
            #            "--network=beszel_default"
          ];
        }
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.beszel";
        ingress = cfg.ingress;
      })
    )
  ];
}
