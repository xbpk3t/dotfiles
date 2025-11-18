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

      # 使用 systemd 内置的重试机制，比自己写 shell 脚本更优雅
      #      serviceConfig = {
      #        Type = "oneshot";
      #        User = "root";
      #
      #        # 重试配置：失败后自动重试，使用指数退避
      #        Restart = "on-failure";
      #      };

      # StartLimit* 作用于 [Unit]，在 NixOS 中需要放在 serviceConfig 之外
      startLimitBurst = 3; # 最多重试 3 次
      startLimitIntervalSec = 3600; # 1 小时内最多重试 5 次 # 1h -> 3600s

      script = ''
        set -euo pipefail

        # Read subscription URL from secret
        SUBSCRIPTION_URL=$(cat ${config.sops.secrets.singboxUrl.path})

        # Create config directory if it doesn't exist
        mkdir -p /etc/sing-box

        # 临时文件，下载成功后再替换正式配置
        TEMP_CONFIG="/etc/sing-box/config.json.tmp"
        CONFIG_FILE="/etc/sing-box/config.json"

        echo "Downloading sing-box configuration from subscription URL..."

        # Download configuration with retry and timeout
        # -f: fail silently on HTTP errors
        # -S: show error even with -s
        # -L: follow redirects
        # --retry 3: retry 3 times on transient errors
        # --retry-delay 5: wait 5 seconds between retries
        # --retry-max-time 60: max 60 seconds for all retries
        # --connect-timeout 30: connection timeout 30 seconds
        # --max-time 120: max total time 120 seconds
        ${pkgs.curl}/bin/curl -fsSL \
          --retry 3 \
          --retry-delay 5 \
          --retry-max-time 60 \
          --connect-timeout 30 \
          --max-time 120 \
          "$SUBSCRIPTION_URL" \
          -o "$TEMP_CONFIG"

        # Verify the downloaded file is valid JSON
        if ! ${pkgs.jq}/bin/jq empty "$TEMP_CONFIG" 2>/dev/null; then
          echo "Error: Downloaded configuration is not valid JSON"
          rm -f "$TEMP_CONFIG"
          exit 1
        fi

        # 原子性替换配置文件
        mv -f "$TEMP_CONFIG" "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"

        echo "Sing-box configuration updated successfully"
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
