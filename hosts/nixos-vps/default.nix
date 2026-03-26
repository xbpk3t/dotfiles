{
  config,
  lib,
  globals,
  userMeta,
  ...
}: let
  inherit (globals.networking) nameservers;
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
      device = diskDevice;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  documentation = {
    # server 默认关闭大部分文档产物，减少系统包体积与无关输出。
    enable = lib.mkDefault false;
    doc.enable = lib.mkDefault false;
    info.enable = lib.mkDefault false;
    man.enable = lib.mkDefault false;

    # NixOS manual/options 文档在本仓库里本来就倾向关闭；这里再次作为 server profile 明确声明。
    # 关闭 NixOS options 文档生成（options.json）。
    # 这会规避当前 Nix 对 make-options-doc 派生出的 builtins.derivation context 警告。
    nixos.enable = lib.mkDefault false;
  };

  programs.command-not-found.enable = lib.mkDefault false;

  fonts.fontconfig.enable = lib.mkDefault false;

  xdg = {
    # 这些 freedesktop/XDG 组件主要服务桌面环境；在 server 上默认关闭更符合角色语义。
    autostart.enable = lib.mkDefault false;
    icons.enable = lib.mkDefault false;
    menus.enable = lib.mkDefault false;
    mime.enable = lib.mkDefault false;
    sounds.enable = lib.mkDefault false;
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
    # NOTE: fallbackDns 已迁移到 settings.Resolve.FallbackDNS
    settings.Resolve.FallbackDNS = nameservers;
  };

  modules.networking = {
    tailscale = {
      enable = true;
      derper = {
        enable = true;
        acmeEmail = userMeta.mail;
      };
    };
  };

  modules.systemd.manager.watchdog = {
    # VPS 属于典型无人值守场景，默认启用 systemd Manager watchdog 兜底。
    # 若后续某台机器的 hypervisor/watchdog 行为特殊，直接在对应 host 覆写即可。
    enable = true;
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
