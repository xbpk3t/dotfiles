{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.netbird;
in {
  #############################################################################
  # NetBird Module - Simplified and Clean
  #
  # This module provides a clean interface for NetBird configuration:
  # - Client: Available on all machines but disabled by default
  # - Server: Disabled by default, enable explicitly when needed
  #
  # Based on official NixOS options:
  # https://mynixos.com/nixpkgs/options/services.netbird
  #############################################################################

  # https://github.com/nukdokplex/ncaa/blob/master/nixos-modules/netbird-client.nix
  options.modules.networking.netbird = {
    #---------------------------------------------------------------------------
    # CLIENT OPTIONS (enabled by default)
    #---------------------------------------------------------------------------
    client = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NetBird client (VPN mesh network)";
      };

      autoStart = mkOption {
        type = types.bool;
        default = true;
        description = "Start the NetBird client automatically on boot";
      };

      port = mkOption {
        type = types.port;
        default = 51820;
        description = "WireGuard port for NetBird client";
      };

      interface = mkOption {
        type = types.str;
        default = "wt0";
        description = "Network interface name for NetBird";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall port for direct peer-to-peer connections";
      };

      hardened = mkOption {
        type = types.bool;
        default = false;
        description = "Run service with hardened systemd options";
      };

      logLevel = mkOption {
        type = types.enum ["debug" "info" "warn" "error"];
        default = "info";
        description = "Log level for NetBird client";
      };
    };

    #---------------------------------------------------------------------------
    # SERVER OPTIONS (disabled by default)
    #---------------------------------------------------------------------------
    server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NetBird server (management, signal, relay)";
      };

      domain = mkOption {
        type = types.str;
        default = "";
        example = "netbird.example.com";
        description = "Domain name for NetBird server";
      };

      enableNginx = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Nginx reverse proxy for NetBird server";
      };
    };
  };

  #############################################################################
  # IMPLEMENTATION
  #############################################################################

  config = mkMerge [
    #---------------------------------------------------------------------------
    # CLIENT CONFIGURATION
    #---------------------------------------------------------------------------
    (mkIf cfg.client.enable {
      # 默认启用所有NixOS机器的netbird client
      # Use native NixOS netbird service with "default" key
      # This creates: netbird-default.service
      # Socket at: /var/run/netbird-default/sock
      # Note: There is no "enable" option - the client is enabled by configuring it
      services.netbird.clients.default = {
        autoStart = cfg.client.autoStart;
        port = cfg.client.port;
        interface = cfg.client.interface;
        openFirewall = cfg.client.openFirewall;
        hardened = cfg.client.hardened;
        logLevel = cfg.client.logLevel;

        # Additional configuration to disable NetBird's SSH server and firewall
        # This allows the system's SSH service to work directly over NetBird
        # DisableFirewall is needed because NetBird's ACL rules are blocking SSH
        config = {
          ServerSSHAllowed = false;
          DisableFirewall = true;
        };
      };

      # Add netbird CLI and nftables to system packages
      # nftables is required for NetBird's firewall manager
      environment.systemPackages = [
        pkgs.netbird
        pkgs.nftables
      ];

      # Create symlink for CLI compatibility
      # The CLI expects /var/run/netbird/sock but service creates /var/run/netbird-default/sock
      systemd.tmpfiles.rules = [
        # Create /var/run/netbird directory
        "d /var/run/netbird 0755 root root -"
        # Create symlink: /var/run/netbird/sock -> /var/run/netbird-default/sock
        "L+ /var/run/netbird/sock - - - - /var/run/netbird-default/sock"
        # Ensure /var/run/netbird-default is accessible
        "d /var/run/netbird-default 0755 netbird-default netbird-default -"
      ];
    })

    #---------------------------------------------------------------------------
    # SERVER CONFIGURATION
    #---------------------------------------------------------------------------
    (mkIf cfg.server.enable {
      services.netbird = {
        enable = true;
        package = pkgs.netbird;
        server = {
          enable = true;
          domain = cfg.server.domain;
          enableNginx = cfg.server.enableNginx;
        };
      };
    })
  ];
}
