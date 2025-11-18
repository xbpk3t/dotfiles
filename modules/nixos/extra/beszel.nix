{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.beszel;
  settings = cfg.settings;
  httpAddress = "${settings.listenAddress}:${toString settings.listenPort}";
  serveArgs =
    settings.domains
    ++ ["--dir" settings.dataDir "--http" httpAddress]
    ++ settings.extraArgs;
  startScript = pkgs.writeShellScript "beszel-hub-start" ''
    exec ${lib.getExe' settings.package "beszel-hub"} serve ${lib.escapeShellArgs serveArgs}
  '';
in {
  options.modules.services.beszel = {
    enable = mkEnableOption "Beszel multi-server monitor";

    settings = mkOption {
      description = "Low-level Beszel options consumed by the systemd unit.";
      default = {};
      type = types.submodule ({...}: {
        options = {
          package = mkOption {
            type = types.package;
            default = pkgs.beszel;
            description = "Beszel package providing the hub binary.";
          };

          dataDir = mkOption {
            type = types.path;
            default = "/var/lib/beszel";
            description = "Persistent data directory passed to `--dir`.";
          };

          listenAddress = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Interface Beszel binds to.";
          };

          listenPort = mkOption {
            type = types.port;
            default = 8090;
            description = "TCP port Beszel listens on.";
          };

          user = mkOption {
            type = types.str;
            default = "beszel";
            description = "System user the service runs as.";
          };

          group = mkOption {
            type = types.str;
            default = "beszel";
            description = "System group the service runs as.";
          };

          domains = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Optional domains forwarded to `beszel-hub serve` (useful when letting Beszel handle TLS).";
          };

          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Extra CLI arguments appended to `beszel-hub serve`.";
          };

          environment = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Environment variables for the Beszel service.";
          };
        };
      });
    };

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "Beszel");
      default = null;
      description = "Expose Beszel through the shared reverse proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      users.groups.${settings.group} = {};
      users.users.${settings.user} = {
        isSystemUser = true;
        group = settings.group;
        home = settings.dataDir;
        description = "Beszel service user";
      };

      systemd.tmpfiles.rules = [
        "d ${settings.dataDir} 0750 ${settings.user} ${settings.group} -"
      ];

      systemd.services.beszel = {
        description = "Beszel monitoring hub";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        environment = mapAttrs (_: v: toString v) settings.environment;
        serviceConfig = {
          ExecStart = startScript;
          Restart = "on-failure";
          RestartSec = 5;
          User = settings.user;
          Group = settings.group;
          WorkingDirectory = settings.dataDir;
        };
      };
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
