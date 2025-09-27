# Darwin networking configuration
# macOS-specific network settings and optimizations
{
  lib,
  myvars,
  ...
}: {
  # Basic networking configuration
  # Note: macOS networking is mostly managed through System Preferences
  # These are the available nix-darwin networking options

  # macOS-specific network optimizations
  # Most network settings are managed through System Preferences
  # Network configuration (will be overridden by host-specific settings)

  networking = {
    # Default network names (can be overridden by host-specific settings)
    hostName = lib.mkDefault "${myvars.username}";
    computerName = lib.mkDefault "${myvars.username}";
    localHostName = lib.mkDefault "${myvars.username}";

    # Network services configuration to suppress warnings
    # This tells nix-darwin which network services to manage
    knownNetworkServices = [
      "Wi-Fi"
      "Ethernet"
      "USB 10/100/1000 LAN"
      "Thunderbolt Bridge"
    ];

    # DNS configuration
    dns = [
      "1.1.1.1" # Cloudflare
      "1.0.0.1" # Cloudflare secondary
      "8.8.8.8" # Google
      "8.8.4.4" # Google secondary
    ];

    # DNS search domains
    search = ["home" "local" "lan"];

    wakeOnLan = {
      enable = false;
    };
    # Note: macOS firewall is managed through System Preferences
    # nix-darwin doesn't provide direct firewall configuration options
  };

  # Network services configuration
  services = {
    # Note: NTP service is not configurable through nix-darwin
    # macOS handles time synchronization automatically

    # Enable SSH daemon
    openssh.enable = true;
    # Note: SSH configuration on macOS is more limited than on NixOS
    # Most SSH settings are managed through /etc/ssh/sshd_config
  };

  # Note: Most network preferences are managed through macOS System Preferences
  # nix-darwin has limited support for network-related system.defaults

  # Network monitoring and diagnostics
  # Most network tools are already in home-manager configuration
}
