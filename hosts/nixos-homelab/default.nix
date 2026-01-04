{
  myvars,
  lib,
  ...
}: let
  hostName = "nixos-homelab";
  inherit (myvars.networking) nameservers;
in {
  imports = [
    ./hardware.nix
  ];

  # 角色标记：走服务器基线，不启用桌面推导
  modules.roles = {
    isDesktop = false;
    isServer = true;
  };

  networking = {
    inherit hostName;
    useNetworkd = true; # 改用 systemd-networkd，更轻量
    networkmanager.enable = false;
    useDHCP = true; # 由 hardware.nix 的接口/或 networkd profiles 提供 DHCP
    inherit nameservers;
  };

  services.resolved = {
    enable = true;
    fallbackDns = nameservers;
  };

  # 启动与电源
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    systemd-boot.enable = true;
    timeout = 5;
    grub.enable = false;
  };

  # 禁止挂起/休眠，保证远程任务不中断
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    powerKey = "ignore";
  };

  modules = {
    hardware.nvidia.enable = false;

    networking = {
      singbox.enable = true;
      tailscale.enable = true;
    };

    # 私网 homelab：显式关闭内置防火墙
    security.enableFirewall = false;

    # 需要远程开发再开启；默认保持关闭即可在 host 覆写
    extra.vscode-remote.enable = lib.mkDefault false;
  };

  # system.stateVersion 保持当前主版本
  system.stateVersion = "24.11";
}
