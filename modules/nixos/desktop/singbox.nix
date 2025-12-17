{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  cfg_path = "/tmp/sing-box/config.json";
in {
  # Sing-box Module - System-level Proxy Service
  #
  # Sing-box requires root privileges to create TUN interfaces.
  # Configuration file is fixed at /etc/sing-box/config.json

  # 只有desktop才需要引入singbox（因为所有VPS默认本身都不需要挂singbox），所以放在这里
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box proxy service";
  };

  config = mkIf cfg.enable {
    # Install sing-box package
    environment.systemPackages = [
      pkgs.sing-box
      pkgs.go-task
      pkgs.curl
      pkgs.jq
    ];

    # 使用 Task 下载订阅配置，解耦主服务
    systemd.services.singbox-update-config = {
      description = "Update Sing-box Configuration from Subscription URL";
      # 最多重试 3 次
      startLimitBurst = 3;
      # 1 小时内最多重试 3 次
      startLimitIntervalSec = 3600;
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        Environment = [
          "CONFIG_FILE=${cfg_path}"
          # PATH 覆盖，确保找到 task/curl/jq
          "PATH=/run/wrappers/bin:/run/current-system/sw/bin:${pkgs.go-task}/bin:${pkgs.curl}/bin:${pkgs.jq}/bin:/usr/bin:/bin"
        ];
        WorkingDirectory = "/home/${myvars.username}/Desktop/dotfiles";
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c 'SINGBOX_URL="$(cat ${config.sops.secrets.singboxUrl.path})" exec ${pkgs.go-task}/bin/task --taskfile "${taskfile_path}" update-config'
        '';
      };
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
      # FIXME 经常会遇到前面的 update-config 失败，导致singbox无法启动，这种问题怎么解决？
      # after = ["network-online.target" "singbox-update-config.service"];
      # requires = ["singbox-update-config.service"];

      serviceConfig = {
        Type = "simple";
        # 统一使用 cfg_path 指定的配置文件
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${cfg_path}";
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
        # 需访问宿主 /tmp/sing-box/config.json，因此禁用 PrivateTmp
        PrivateTmp = false;
      };
    };
  };
}
