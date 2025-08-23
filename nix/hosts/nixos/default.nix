# Minimal NixOS test system configuration
{ username, hostname, pkgs, lib, ... }:

{
  # Boot configuration for VM - disable bootloader for virtualized environments
  boot = {
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

    # Virtualization-specific settings
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };


  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Swap
  swapDevices = [ ];

  # Networking
  networking.hostName = hostname;
  networking.useDHCP = lib.mkDefault true;

  # SSH - minimal configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    fastfetch
    neofetch
    vim
    git
  ];

  # User configuration
  users.users.${username} = {
    isNormalUser = true;
    password = "nixos";
    extraGroups = [ "wheel" ];
  };

  users.users.root.password = "nixos";

  # Sudo configuration
  security.sudo.wheelNeedsPassword = false;

  # System state version
  system.stateVersion = "24.05";
}
