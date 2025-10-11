{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.networking.netbird;
in {
  options.modules.networking.netbird = {
    enable = mkEnableOption "Enable netbird service";

    clients = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable this netbird client instance";
          };

          autoStart = mkOption {
            type = types.bool;
            default = true;
            description = "Start the service with the system";
          };

          port = mkOption {
            type = types.port;
            default = 51820;
            description = "Port the NetBird client listens on";
          };

          interface = mkOption {
            type = types.str;
            default = "wt0";
            description = "Name of the network interface managed by this client";
          };

          name = mkOption {
            type = types.str;
            default = "";
            description = "Primary name for use (as a suffix) in: systemd service name, hardened user name and group, systemd *D";
          };

          openFirewall = mkOption {
            type = types.bool;
            default = false;
            description = "Opens up firewall port for communication between NetBird peers directly over LAN or public IP";
          };

          hardened = mkOption {
            type = types.bool;
            default = false;
            description = "Hardened service: runs as a dedicated user with minimal set of permissions";
          };

          logLevel = mkOption {
            type = types.enum [ "debug" "info" "warn" "error" ];
            default = "info";
            description = "Log level of the NetBird daemon";
          };
        };
      });
      default = {};
      description = "Attribute set of NetBird client daemons";
    };

    server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable netbird server";
      };

      domain = mkOption {
        type = types.str;
        default = "netbird.example.com";
        description = "Domain for the netbird server";
      };

      enableNginx = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Nginx reverse-proxy for the netbird server services";
      };

      dashboard = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable the static netbird dashboard frontend";
        };

        domain = mkOption {
          type = types.str;
          default = "";
          description = "The domain under which the dashboard runs";
        };

        enableNginx = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable Nginx reverse-proxy to serve the dashboard";
        };
      };

      management = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable Netbird Management Service";
        };

        domain = mkOption {
          type = types.str;
          default = "";
          description = "The domain under which the management API runs";
        };

        enableNginx = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable Nginx reverse-proxy for the netbird management service";
        };

        port = mkOption {
          type = types.port;
          default = 9090;
          description = "Internal port of the management server";
        };

        metricsPort = mkOption {
          type = types.port;
          default = 8081;
          description = "Internal port of the metrics server";
        };
      };

      signal = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable Netbird's Signal Service";
        };

        domain = mkOption {
          type = types.str;
          default = "";
          description = "The domain name for the signal service";
        };

        enableNginx = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable Nginx reverse-proxy for the netbird signal service";
        };

        port = mkOption {
          type = types.port;
          default = 10000;
          description = "Internal port of the signal server";
        };

        metricsPort = mkOption {
          type = types.port;
          default = 8082;
          description = "Internal port of the metrics server";
        };
      };

      coturn = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable a Coturn server for Netbird";
        };

        domain = mkOption {
          type = types.str;
          default = "";
          description = "The domain under which the coturn server runs";
        };

        useAcmeCertificates = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to use ACME certificates corresponding to the given domain for the server";
        };

        user = mkOption {
          type = types.str;
          default = "netbird";
          description = "The username used by netbird to connect to the coturn server";
        };

        password = mkOption {
          type = types.str;
          default = "";
          description = "The password of the user used by netbird to connect to the coturn server";
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Client configuration - use the flexible clients approach
    {
      # Add netbird package to system packages so the CLI is available
      environment.systemPackages = [ pkgs.netbird ];

      services.netbird.clients =
        let
          enabledClients = lib.filterAttrs (name: clientCfg: clientCfg.enable) cfg.clients;

          # For single client setup, use "default" as the key to get netbird.service
          # For multiple clients, each gets its own service name
          isSingleClient = (lib.length (lib.attrNames enabledClients)) == 1;

          clientOptions = lib.mapAttrs
            (name: clientCfg: {
              autoStart = clientCfg.autoStart;
              port = clientCfg.port;
              interface = clientCfg.interface;
              # Use empty name for single client to get default service name "netbird.service"
              # Otherwise CLI cannot connect: dial unix /var/run/netbird/sock: connect: no such file or directory
              name = if isSingleClient then "" else (if clientCfg.name != "" then clientCfg.name else name);
              openFirewall = clientCfg.openFirewall;
              hardened = clientCfg.hardened;
              logLevel = clientCfg.logLevel;
            })
            enabledClients;

          # If single client, rename the key to "default" to avoid suffix
          finalOptions = if isSingleClient && (lib.length (lib.attrNames clientOptions) == 1)
            then { "default" = lib.head (lib.attrValues clientOptions); }
            else clientOptions;
        in
        finalOptions;
    }

    # Server configuration
    (mkIf cfg.server.enable {
      services.netbird.server = {
        enable = true;
        domain = cfg.server.domain;
        enableNginx = cfg.server.enableNginx;

        dashboard = {
          enable = cfg.server.dashboard.enable;
          domain = if cfg.server.dashboard.domain != "" then cfg.server.dashboard.domain else cfg.server.domain;
          enableNginx = cfg.server.dashboard.enableNginx;
        };

        management = {
          enable = cfg.server.management.enable;
          domain = if cfg.server.management.domain != "" then cfg.server.management.domain else cfg.server.domain;
          enableNginx = cfg.server.management.enableNginx;
          port = cfg.server.management.port;
          metricsPort = cfg.server.management.metricsPort;
        };

        signal = {
          enable = cfg.server.signal.enable;
          domain = if cfg.server.signal.domain != "" then cfg.server.signal.domain else cfg.server.domain;
          enableNginx = cfg.server.signal.enableNginx;
          port = cfg.server.signal.port;
          metricsPort = cfg.server.signal.metricsPort;
        };

        coturn = {
          enable = cfg.server.coturn.enable;
          domain = if cfg.server.coturn.domain != "" then cfg.server.coturn.domain else cfg.server.domain;
          useAcmeCertificates = cfg.server.coturn.useAcmeCertificates;
          user = cfg.server.coturn.user;
          password = cfg.server.coturn.password;
        };
      };
    })
  ]);
}