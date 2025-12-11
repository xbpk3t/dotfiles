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

  #     experimental.cache_file = {
  #      enabled = true;
  #      path = "/var/cache/sing-box/cache.db";
  #      store_fakeip = true;
  #    };

  #     experimental.cache_file = {
  #      enabled = true;
  #      path = "/var/cache/sing-box/cache.db";
  #      store_fakeip = true;
  #    };
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box proxy service";
  };

  config = mkIf cfg.enable {
    # Install sing-box package
    environment.systemPackages = [pkgs.sing-box];

    # Systemd service to download sing-box configuration from subscription URL
    # 独立的配置下载服务，与 sing-box 主服务解耦
    systemd.services.singbox-update-config = {
      description = "Update Sing-box Configuration from Subscription URL";
      # StartLimit* 作用于 [Unit]，在 NixOS 中需要放在 serviceConfig 之外
      startLimitBurst = 3; # 最多重试 3 次
      startLimitIntervalSec = 3600; # 1 小时内最多重试 5 次 # 1h -> 3600s
      script = ''
      '';
    };

    # Systemd timer to update sing-box configuration every 12 hours
    systemd.timers.singbox-update-config = {
      description = "Timer for Sing-box Configuration Update";
      wantedBy = ["timers.target"];

      timerConfig = {
        # 系统启动后 5 分钟首次运行
        OnBootSec = "5min";
        # 之后每 12 小时运行一次
        OnUnitActiveSec = "12h";
        # 如果错过了运行时间，立即运行
        Persistent = true;
        # 添加随机延迟 0-30 分钟，避免所有机器同时请求
        RandomizedDelaySec = "30min";
      };
    };

    # Create systemd system service for sing-box (requires root for TUN interface)
    systemd.services.singbox = {
      description = "Sing-box Proxy Service";
      wantedBy = ["multi-user.target"];
      # 确保配置文件存在后再启动
      #      after = ["network.target" "singbox-update-config.service"];
      after = ["network.target"];
      # 首次启动前必须先下载配置
      requires = ["singbox-update-config.service"];

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
