{
  config,
  lib,
  myvars,
  ...
}: let
  inherit (myvars.networking) nameservers;
  diskDevice = lib.attrByPath ["disko" "devices" "disk" "vda" "device"] "/dev/vda" config;
in {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./modules.nix
  ];

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    efi.efiSysMountPoint = lib.mkForce "/boot/efi";
    grub = {
      enable = true;
      version = 2;
      device = lib.mkDefault diskDevice;
      efiSupport = lib.mkDefault true;
      efiInstallAsRemovable = lib.mkDefault true;
    };
  };

  networking = {
    hostName = lib.mkDefault "nixos-vps";
    useDHCP = lib.mkDefault true;
    nameservers = lib.mkDefault nameservers;
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved = {
    enable = lib.mkDefault true;
    fallbackDns = nameservers;
  };

  services.vpsSecurity.enable = lib.mkDefault true;

  hardware.enableRedistributableFirmware = lib.mkForce false;

  # Disable scheduled upgrades to avoid conflicts with immutable deployments.
  system.autoUpgrade.enable = lib.mkForce false;
  systemd.services."nixos-upgrade".enable = lib.mkForce false;
  systemd.timers."nixos-upgrade".enable = lib.mkForce false;

  system.stateVersion = "24.11";
}
