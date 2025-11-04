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

  system.stateVersion = "24.11";
}
