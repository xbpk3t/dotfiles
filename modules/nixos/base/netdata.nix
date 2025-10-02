{
  config,
  pkgs,
  lib,
  ...
}: {
  services.netdata = {
    enable = true;
    package = pkgs.netdata.override {withCloudUi = true;};

    # Configuration file settings
    config = {
      global = {
        # The default database size is 3600 seconds (1 hour)
        # Increase to 86400 (24 hours) for better historical data
        "history" = "86400";

        # Update every second
        "update every" = "1";

        # Memory mode: save = save on exit, map = memory mapped, ram = only in RAM
        "memory mode" = "ram";

        # Error log
        "error log" = "syslog";

        # Access log
        "access log" = "none";

        # Debug flags
        "debug flags" = "0x0000000000000000";

        # Hostname
        "hostname" = config.networking.hostName;
      };

      # Web server configuration
      web = {
        "mode" = "static-threaded";
        "listen backlog" = "4096";
        "default port" = "19999";
        "bind to" = "0.0.0.0:19999"; # 修复：明确指定绑定地址和端口
        "disconnect idle clients after seconds" = "60";
        "timeout for first request" = "60";
        "accept a streaming request every seconds" = "0";
        "respect do not track policy" = "no";
        "x-frame-options response header" = "";
        "access log" = "none";

        # CORS 设置解决 origin URL 问题
        "cors allowed origins" = "*";
        "allow cross domain requests from" = "*";

        # Web 服务器配置 - 指向正确的静态文件路径
        "web files owner" = "root";
        "web files group" = "root";

        # 设置静态文件路径 - NixOS 中的 Netdata 静态文件通常在这里
        "web root path" = "${pkgs.netdata}/share/netdata/web";

        # Netdata 2.5+ 访问控制配置 - 解决 "file does not exist" 错误
        "allow connections from" = "localhost *"; # 允许本地和任何IP连接
        "allow dashboard from" = "localhost *"; # 允许访问dashboard
        "allow management from" = "localhost"; # 只允许本地管理
        "allow badges from" = "*"; # 允许badge访问
        "allow streaming from" = "*"; # 允许数据流
        "allow netdata.conf from" = "localhost"; # 只允许本地访问配置文件

        # DNS解析设置 - Netdata 2.5+ 推荐设置
        "allow connections by dns" = "heuristic";
        "allow dashboard by dns" = "heuristic";
        "allow management by dns" = "no";

        # 启用gzip压缩
        "enable gzip compression" = "yes";
        "gzip compression strategy" = "default";
        "gzip compression level" = "3";
      };

      # Plugin configuration
      plugins = {
        "proc" = "yes";
        "diskspace" = "yes";
        "cgroups" = "yes";
        "tc" = "no";
        "idlejitter" = "no";
        "enable running new plugins" = "yes";
        "check for new plugins every" = "60";
        "slabinfo" = "no";
      };

      # Health monitoring
      health = {
        "enabled" = "yes";
        "in memory max health log entries" = "1000";
        "script to execute on alarm" = "${pkgs.netdata}/libexec/netdata/plugins.d/alarm-notify.sh";
        "health configuration directory" = "${pkgs.netdata}/lib/netdata/conf.d/health.d";
        "postpone alarms during hibernation for seconds" = "60";
        "run at least every seconds" = "10";
      };

      # Registry configuration
      registry = {
        "enabled" = "no";
      };
    };

    # Python plugin configuration
    python = {
      enable = true;
      # Recommended python plugins
      extraPackages = ps:
        with ps; [
          psutil
          pyyaml
        ];
    };

    # Enable specific collectors
    configDir = {
      "python.d.conf" = pkgs.writeText "python.d.conf" ''
        # Python plugin configuration
        enabled: yes
        default_run: yes

        # Enable specific python modules
        nginx: no
        apache: no
        mysql: no
        postgres: no
        redis: no
        mongodb: no
      '';

      "go.d.conf" = pkgs.writeText "go.d.conf" ''
        # Go plugin configuration
        enabled: yes
        default_run: yes

        # Enable specific go modules
        docker: yes
        systemd: yes
        nginx: no
        apache: no
      '';

      "charts.d.conf" = pkgs.writeText "charts.d.conf" ''
        # Shell charts plugin configuration
        enabled: no
      '';

      "node.d.conf" = pkgs.writeText "node.d.conf" ''
        # Node.js plugin configuration
        enabled: no
      '';
    };
  };

  # Open firewall for netdata web interface
  networking.firewall.allowedTCPPorts = [19999];

  # Ensure netdata user has access to necessary system information
  users.users.netdata = {
    extraGroups = ["docker" "systemd-journal"];
  };

  # Systemd service configuration
  systemd.services.netdata = {
    serviceConfig = {
      # Restart on failure
      Restart = "on-failure";
      RestartSec = "30s";

      # Resource limits
      LimitNOFILE = lib.mkForce 30000;

      # Security settings
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "full";

      # Capabilities
      AmbientCapabilities = [
        "CAP_DAC_READ_SEARCH"
        "CAP_SYS_PTRACE"
      ];
      CapabilityBoundingSet = [
        "CAP_DAC_READ_SEARCH"
        "CAP_SYS_PTRACE"
        "CAP_SETUID"
      ];
    };
  };
}
