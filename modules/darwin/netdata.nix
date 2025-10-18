{
  pkgs,
  myvars,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.services.netdata;
in {
  config = mkIf cfg.enable {
    # Netdata real-time monitoring
    services.netdata = {
      enable = true;

      # Package - use default netdata package
      package = pkgs.netdata.override {withCloudUi = true;};

      # Working directory
      workDir = "/var/lib/netdata";

      # Cache directory
      cacheDir = "/var/cache/netdata";

      # Log directory
      logDir = "/var/log/netdata";

      # Enable web interface on port 19999
      # Access via: http://localhost:19999
      config = ''
        [global]
          # Run as daemon
          run as user = ${myvars.username}
          web files owner = ${myvars.username}
          web files group = staff

          # Set default bind address to localhost on port 19999
          bind to = localhost:19999

          # Update frequency (seconds) - 5 seconds for better real-time monitoring
          update every = 5

          # History retention - calculate for 1 week of data
          # 1 week = 7 days * 24 hours * 60 minutes * 60 seconds / 5 second updates = 120,960 entries
          history = 120960

          # Memory usage optimization - use db mode for long-term storage
          memory mode = db

          # Database directory for persistent storage
          db directory = /var/lib/netdata

          # Disable cloud features
          cloud enabled = no

          # Set web directories
          web files directory = /var/cache/netdata/www

        [plugins]
          # Enable all CPU, memory, disk, and network monitoring
          charts.d enable all = yes

          # Enable process monitoring
          proc enable all = yes

          # Enable disk space monitoring
          diskspace enable all = yes

          # Enable network monitoring
          netdata enable all = yes

        [web]
          # Enable web interface
          mode = static-threaded

          # Set default view
          default destination = dashboard

          # Enable dashboard
          dashboard enabled = yes

          # Enable alarms
          alarms = yes

          # Enable health monitoring
          health enabled = yes

          # Set web root
          web root = /var/cache/netdata/www
      '';
    };
    # Open firewall for netdata (if needed for external access)
    networking.firewall.allowedTCPPorts = [19999];

    # Direct access via localhost:19999 (no nginx proxy needed)
  };
}
