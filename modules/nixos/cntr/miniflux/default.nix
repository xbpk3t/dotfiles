{
  config,
  lib,
  mylib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.miniflux;
  composeFile = pkgs.writeText "miniflux-compose.yml" (builtins.readFile ./compose.yml);
  serviceName = "miniflux";
  stateDir = "/var/lib/${serviceName}";
in {
  # https://mynixos.com/nixpkgs/options/services.miniflux
  # https://mynixos.com/nixpkgs/package/miniflux

  # Nextflux
  # https://github.com/electh/nextflux
  # https://github.com/electh/nextflux/blob/main/compose.yml

  # https://github.com/miniflux/v2/issues/2368
  # https://github.com/miniflux/v2/issues/2711
  # https://github.com/miniflux/v2/issues/2720
  # https://github.com/miniflux/v2/issues/2369
  # https://github.com/miniflux/v2/issues/2026
  # https://github.com/miniflux/v2/issues/2862
  # https://github.com/miniflux/v2/issues/2066
  # https://github.com/miniflux/v2/issues/2863
  # https://github.com/miniflux/v2/issues/2873
  # https://github.com/miniflux/v2/issues/2868
  # https://github.com/miniflux/v2/issues/2874

  # https://github.com/miniflux/v2/issues/2911
  # https://github.com/miniflux/v2/issues/2843
  # https://github.com/miniflux/v2/pull/2143
  # https://github.com/miniflux/v2/pull/2150
  # https://github.com/miniflux/v2/pull/2392
  # https://github.com/miniflux/v2/pull/2421
  # https://github.com/miniflux/v2/pull/2415

  options.modules.services.miniflux = {
    enable = mkEnableOption "Miniflux stack managed via podman-compose";

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "Miniflux (compose)");
      default = null;
      description = "Expose Miniflux through the shared reverse proxy.";
    };

    projectName = mkOption {
      type = types.str;
      default = "miniflux";
      description = "COMPOSE_PROJECT_NAME used by podman-compose.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${stateDir} 0750 root root -"
      ];

      systemd.services.${serviceName} = {
        description = "Miniflux via podman-compose";
        path = [pkgs.podman pkgs.podman-compose pkgs.coreutils];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        environment = {
          COMPOSE_PROJECT_NAME = cfg.projectName;
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          WorkingDirectory = stateDir;
          ExecStart = ''
            ${pkgs.podman-compose}/bin/podman-compose -f ${composeFile} up -d
          '';
          ExecStop = ''
            ${pkgs.podman-compose}/bin/podman-compose -f ${composeFile} down
          '';
        };
      };
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.miniflux";
        ingress = cfg.ingress;
      })
    )
  ];
}
