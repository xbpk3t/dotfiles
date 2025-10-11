{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
in {
  #############################################################################
  # Sing-box Module - System-level Proxy Service
  #
  # Sing-box requires root privileges to create TUN interfaces.
  # Configuration file is fixed at /etc/sing-box/config.json
  #############################################################################

  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box proxy service";
  };

  config = mkIf cfg.enable {
    # Install sing-box package
    environment.systemPackages = [pkgs.sing-box];

    # Create systemd system service for sing-box (requires root for TUN interface)
    # FIXME 替换为直接从 sub-store 的URL拉取
    systemd.services.sing-box = {
      description = "Sing-box Proxy Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        # Fixed configuration path - all machines use /etc/sing-box/config.json
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /etc/sing-box/config.json";
        Restart = "always";
        RestartSec = "5s";

        # Security: Required capabilities for TUN interface
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";

        # Run as root (required for TUN interface creation)
        User = "root";

        # Minimal security hardening
        # Note: Cannot use ProtectHome or ProtectSystem=strict as they would
        # prevent reading config from /etc or accessing /home
        NoNewPrivileges = false; # Must be false for capabilities
        PrivateTmp = true;
      };
    };
  };
}
