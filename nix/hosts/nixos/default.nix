# Minimal NixOS test system configuration
{ config, pkgs, lib, username, hostname, ... }:

{
  # Boot configuration for VM - disable systemd-boot and use GRUB
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

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
