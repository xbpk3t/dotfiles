{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.uptime;
  containerName = "uptiem";
  stateDir = "/var/lib/${containerName}";
in {
  options.modules.services.uptime = {
    enable = mkEnableOption "Uptime Kuma (Docker)";

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "Uptime Kuma");
      default = null;
      description = "Expose Uptime Kuma through the shared reverse proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${stateDir} 0750 root root -"
      ];

      virtualisation.oci-containers.containers.${containerName} = {
        autoStart = true;
        image = "louislam/uptime-kuma:2";
        volumes = [
          "${stateDir}:/app/data:rw"
        ];
        ports = [
          "127.0.0.1:3001:3001/tcp"
        ];
        log-driver = "journald";
      };
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.uptime";
        ingress = cfg.ingress;
      })
    )
  ];
}
