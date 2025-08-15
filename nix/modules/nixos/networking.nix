# NixOS networking configuration
{ hostname, ... }:

{
  networking = {
    hostName = hostname;

    # Enable networking
    networkmanager.enable = true;

    # Firewall configuration (migrated from ansible firewall.yml)
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22    # SSH
        80    # HTTP
        443   # HTTPS
      ];
      # Additional ports can be configured per-host
    };

    # DNS configuration
    nameservers = [ "8.8.8.8" "8.8.4.4" ];

    # Hosts file entries (from k8s-optimize.sh)
    # These will be configured per-host as needed
    extraHosts = ''
      # K8s cluster hosts will be added per-host
    '';
  };

  # Time synchronization (equivalent to ansible timezone.yml NTP)
  services.timesyncd.enable = true;
}
