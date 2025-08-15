# NixOS services configuration
{ ... }:

{
  # SSH service configuration (migrated from ansible ssh.yml)
  services.openssh = {
    enable = true;
    ports = [ 22 ]; # Can be overridden per-host
    settings = {
      # Security settings (from ansible ssh.yml)
      PasswordAuthentication = false; # Disable password auth in production
      PubkeyAuthentication = true;
      PermitRootLogin = "yes"; # Can be restricted per-host

      # Performance settings (from ansible ssh.yml)
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
      UseDNS = false;
    };
  };

  # Container runtime (migrated from ansible docker.yml)
  virtualisation = {
    podman = {
      enable = true;
      # Docker compatibility
      dockerCompat = true;
      # Default network settings
      defaultNetwork.settings.dns_enabled = true;
    };

    # Enable containers
    containers.enable = true;
  };

  # System monitoring and logging
  services = {
    # Log rotation (equivalent to ansible log retention)
    logrotate = {
      enable = true;
      settings = {
        global = {
          rotate = 30; # Keep 30 days of logs
          daily = true;
          compress = true;
          delaycompress = true;
          missingok = true;
          notifempty = true;
        };
      };
    };
  };
}
