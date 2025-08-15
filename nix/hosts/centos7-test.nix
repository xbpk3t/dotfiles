# CentOS 7 Test Container Configuration
# Replaces ansible inventory host: centos7-test (localhost:34225)
{ ... }:

{
  # Import shared NixOS modules
  imports = [
    ../modules/nixos
    ../modules/shared
  ];

  # Host-specific configuration
  networking = {
    hostName = "centos7-test";

    # More permissive firewall for testing
    firewall = {
      enable = false; # Disabled for testing environment
    };
  };

  # SSH configuration for test container
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      # Test environment settings (less secure, more convenient)
      PasswordAuthentication = true;  # Allow password auth for testing
      PubkeyAuthentication = true;
      PermitRootLogin = "yes";

      # Performance settings
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
      UseDNS = false;
    };
  };

  # Test user configuration
  users.users = {
    # Docker user for container access
    docker = {
      isNormalUser = true;
      home = "/home/docker";
      description = "Docker test user";
      extraGroups = [ "wheel" "docker" ];
      shell = "/run/current-system/sw/bin/bash";
      # Set password for testing (in production, use SSH keys)
      initialPassword = "docker";
    };
  };

  # Container-specific configuration
  boot = {
    # Container doesn't need bootloader
    isContainer = true;

    # Minimal kernel modules for container
    kernelModules = [ ];
  };

  # Test environment variables
  environment.variables = {
    ENVIRONMENT = "staging";
  };

  # Reduced system limits for test environment
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "4096";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "4096";
    }
  ];

  # System state version
  system.stateVersion = "24.05";
}
