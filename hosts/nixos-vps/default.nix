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
    ./disko.nix
    ./hardware.nix
  ];

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    efi.efiSysMountPoint = lib.mkForce "/boot/efi";
    grub = {
      enable = true;
      version = 2;
      device = diskDevice;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  networking = {
    # hostName 由 inventory 注入；这里提供默认值，避免单机调试时为空
    hostName = lib.mkDefault "nixos-vps";
    useDHCP = true;
    nameservers = nameservers;
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved = {
    enable = true;
    fallbackDns = nameservers;
  };

  modules.networking = {
    tailscale = {
      enable = true;
      derper = {
        enable = true;
        acmeEmail = myvars.mail;
      };
    };
  };

  hardware.enableRedistributableFirmware = lib.mkForce false;

  # Disable scheduled upgrades to avoid conflicts with immutable deployments.
  system.autoUpgrade.enable = lib.mkForce false;
  systemd.services."nixos-upgrade".enable = lib.mkForce false;
  systemd.timers."nixos-upgrade".enable = lib.mkForce false;

  # Avoid strict overcommit which caused nix-daemon forks to fail ("Cannot allocate memory").
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = lib.mkForce 0;
    "vm.overcommit_ratio" = lib.mkForce 100;
  };

  services = {
    dokploy-server.enable = false;
    singbox-server.enable = true;
  };

  # k3s agent：VPS 统一作为 worker 节点
  modules.extra.k3s = {
    enable = true;
    role = "agent";
    # serverIP 由 inventory 注入，避免多处重复维护
    serverPort = 6443;
  };
  system.stateVersion = "24.11";
}
