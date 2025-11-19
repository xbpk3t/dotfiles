{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.portainer;
  containerName = "portainer";
  stateDir = "/var/lib/${containerName}";
in {
  options.modules.services.portainer = {
    enable = mkEnableOption "Portainer CE (container)";

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "Portainer");
      default = null;
      description = "Expose Portainer via the shared reverse proxy.";
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
          image = "portainer/portainer-ce:2.26.0-alpine";
          volumes = [
            "${stateDir}:/data:rw"
            "/var/run/docker.sock:/var/run/docker.sock:rw"
            #            "/home/luck/Desktop/dotfiles/manifests/docker/portainer/data:/data:rw"
            #            "/var/run/docker.sock:/var/run/docker.sock:rw"
          ];
          ports = [
            "9000:9000/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            #            "--network-alias=portainer"
            #            "--network=portainer_default"
          ];
        }
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.portainer";
        ingress = cfg.ingress;
      })
    )
  ];
}
