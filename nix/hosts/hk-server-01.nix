# HK Server 01 Configuration
# Replaces ansible inventory host: hk-server-01 (47.79.17.202)
{ ... }:

{
  # Import shared NixOS modules
  imports = [
    ../modules/nixos
    ../modules/shared
  ];

  # Host-specific configuration
  networking = {
    hostName = "hk-server-01";

    # Firewall configuration for production server
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22    # SSH
        80    # HTTP
        443   # HTTPS
        # Add more ports as needed
      ];
    };

    # Production server hosts file (from k8s-optimize.sh if needed)
    extraHosts = ''
      # Add K8s cluster hosts if this becomes a K8s node
      # 192.168.8.10 k8s-master
      # 192.168.8.11 k8s-node1
      # 192.168.8.12 k8s-node2
    '';
  };

  # SSH configuration for production
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      # Production security settings
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      PermitRootLogin = "prohibit-password"; # More secure for production

      # Performance settings
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
      UseDNS = false;
    };
  };

  # Production-specific system limits
  security.pam.loginLimits = [
    # Higher limits for production
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "1048576";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
  ];

  # Boot configuration (will need to be customized based on actual hardware)
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda"; # Adjust based on actual disk layout
      };
    };
  };

  # File systems (will need to be customized based on actual hardware)
  fileSystems."/" = {
    device = "/dev/sda1"; # Adjust based on actual disk layout
    fsType = "ext4";
  };

  # Production environment variables
  environment.variables = {
    ENVIRONMENT = "production";
  };

  # System state version
  system.stateVersion = "24.05";
}
