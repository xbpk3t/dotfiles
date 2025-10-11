{
  config,
  pkgs,
  lib,
  myvars,
  ...
}: let
  cfg = config.modules.networking.singbox;
in {
  options.modules.networking.singbox = {
    enable = lib.mkEnableOption "sing-box service";

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/${myvars.username}/config.json";
      description = "Path to sing-box configuration file";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install sing-box package
    environment.systemPackages = [ pkgs.sing-box ];

    # Create systemd system service for sing-box (requires root for TUN interface)
    # FIXME 替换为直接从 sub-store 的URL拉取
    systemd.services.sing-box = {
      description = "Sing-box Proxy Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${cfg.configPath}";
        Restart = "always";
        RestartSec = "5s";

        # Security hardening
        # Allow CAP_NET_ADMIN for TUN interface creation
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";

        # Run as root (required for TUN)
        # Note: sing-box needs root to create TUN interface
        User = "root";

        # Additional security
        NoNewPrivileges = false;  # Must be false for capabilities
        ProtectSystem = "strict";
        ProtectHome = "read-only";  # Need to read config from /home
        PrivateTmp = true;
      };
    };
  };
}
