# Minimal NixOS test system configuration
# This file contains host-specific configurations that should not be shared between different machines
{
  username,
  hostname,
  lib,
  ...
}: {
  # Host-specific networking configuration
  networking = {
    # Set the hostname for this specific machine
    hostName = hostname;
    # Use DHCP by default for network configuration
    useDHCP = lib.mkDefault true;
  };

  # Host-specific boot configuration
  boot = {
    # Bootloader configuration for virtualized environments
    loader = {
      systemd-boot = {
        enable = false;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = false;
      grub = {
        enable = false;
        device = "nodev";
      };
    };

    # Virtualization-specific kernel modules
    initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];

    # File systems specific to this host
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    # System state version - this is host-specific and should not be changed after initial installation
    system.stateVersion = "24.05";
  };

  # Host-specific user configuration
  users.users.${username} = {
    # Create a normal user with the specified username
    isNormalUser = true;
    # Set default password
    password = "nixos";
    # Add user to wheel group for sudo access
    extraGroups = ["wheel"];
  };

  # Set root user password
  users.users.root.password = "nixos";

  # Host-specific security configuration
  security = {
    # Allow wheel group members to use sudo without password
    sudo.wheelNeedsPassword = false;
  };

  # Import shared and NixOS-specific modules
  imports = [
    ../../modules/nixos
    ../../modules/base
  ];
}
