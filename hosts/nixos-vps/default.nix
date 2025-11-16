{
  lib,
  myvars,
  ...
}: let
  hostName = "nixos-vps";
  inherit (myvars.networking) nameservers;
in {
  networking = {
    inherit hostName;
    useDHCP = lib.mkDefault true;
    nameservers = lib.mkDefault nameservers;
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved = {
    enable = lib.mkDefault true;
    fallbackDns = nameservers;
  };

  hardware.enableRedistributableFirmware = lib.mkDefault false;

  # Disable the scheduled nixos-upgrade job because the VPS root FS is read-only during deployments.
  system.autoUpgrade.enable = lib.mkForce false;
  systemd.services."nixos-upgrade".enable = lib.mkForce false;
  systemd.timers."nixos-upgrade".enable = lib.mkForce false;

  system.stateVersion = "24.11";
}
