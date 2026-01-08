{
  config,
  lib,
  myvars,
  mylib,
  ...
}: let
  inherit (myvars.networking) nameservers;
  diskDevice = lib.attrByPath ["disko" "devices" "disk" "vda" "device"] "/dev/vda" config;
in {
  imports = mylib.scanPaths ./.;

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
    hostName = let
      targetHost = config.deployment.targetHost or null;
      sanitized =
        if targetHost == null
        then null
        else lib.strings.replaceStrings ["." ":" "/"] ["-" "-" "-"] targetHost;
    in
      if sanitized == null
      then "nixos-vps"
      else "nixos-vps-${sanitized}";
    useDHCP = true;
    nameservers = nameservers;
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved = {
    enable = true;
    fallbackDns = nameservers;
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
    dokploy-server.enable = true;
    # 注意cf套壳没做 配置化启用。需要去 vars里配置，如果 singboxServers 里该 IP 的节点 有 cf 字段 → 自动开 CF inbound；如果没有 cf 字段 → 不会开 CF inbound
    singbox-server.enable = true;
  };

  networking.firewall.allowedTCPPorts = lib.mkAfter [80 443];

  system.stateVersion = "24.11";
}
