{
  config,
  pkgs,
  lib,
  ...
}: {
  services.netdata = {
    enable = true;
    package = pkgs.netdata;

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
        "bind to" = "*";
        "disconnect idle clients after seconds" = "60";
        "timeout for first request" = "60";
        "accept a streaming request every seconds" = "0";
        "respect do not track policy" = "no";
        "x-frame-options response header" = "";
        "allow connections from" = "localhost *";
        "allow dashboard from" = "localhost *";
        "allow badges from" = "*";
        "allow streaming from" = "*";
        "allow netdata.conf from" = "localhost fd* 10.* 192.168.* 172.16.* 172.17.* 172.18.* 172.19.* 172.20.* 172.21.* 172.22.* 172.23.* 172.24.* 172.25.* 172.26.* 172.27.* 172.28.* 172.29.* 172.30.* 172.31.*";
        "allow management from" = "localhost";
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
