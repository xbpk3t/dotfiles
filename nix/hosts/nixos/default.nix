# Minimal NixOS configuration for VM
{ config, pkgs, lib, username, hostname, ... }:

{
  # Disable bootloader entirely for VM
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Networking
  networking.hostName = hostname;
  networking.useDHCP = true;

  # SSH
  services.openssh.enable = true;

  # Enable zsh at system level
  programs.zsh.enable = true;

  # User configuration - use the passed username parameter
  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    password = "nixos";
    extraGroups = [ "wheel" ];
    home = "/home/${username}";
    shell = pkgs.zsh;
  };

  users.users.root.password = "nixos";

  # Sudo configuration
  security.sudo.wheelNeedsPassword = false;

  # System state version
  system.stateVersion = "24.05";
}
