{
  globals,
  lib,
  stateVersion,
  ...
}:
let
  hostName = "nixos-homelab";
  inherit (globals.networking) nameservers;
in
{
  imports = [
    ./hardware.nix
  ];

  networking = {
    inherit hostName;
    useNetworkd = true; # 改用 systemd-networkd，更轻量
    networkmanager.enable = false;
    useDHCP = true; # 由 hardware.nix 的接口/或 networkd profiles 提供 DHCP
    # 避免 /etc/resolv.conf 指向 127.0.0.53（stub），显式使用 systemd-resolved
    # 的真实上游解析结果。
    useHostResolvConf = lib.mkForce false;
    inherit nameservers;
  };

  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = nameservers;
  };

  # 显式使用 systemd-resolved 的真实上游解析结果，避免依赖 stub-resolv.conf。
  environment.etc."resolv.conf".source = lib.mkForce "/run/systemd/resolve/resolv.conf";

  # 启动与电源
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    systemd-boot.enable = true;
    timeout = 5;
    grub.enable = false;
  };

  # 禁止挂起/休眠，保证远程任务不中断
  # 说明：改用 systemd.sleep.settings.Sleep（NixOS 选项已移除 extraConfig）
  systemd.sleep.settings.Sleep = {
    # 关键：禁止 Suspend（避免远程任务被挂起中断）
    AllowSuspend = "no";
    # 关键：禁止 Hibernation（避免电源切换导致服务退出）
    AllowHibernation = "no";
    # 关键：禁止 Suspend-then-Hibernate（避免二阶段动作导致服务退出）
    AllowSuspendThenHibernate = "no";
    # 关键：禁止 HybridSleep（混合睡眠）
    AllowHybridSleep = "no";
  };

  services.logind = {
    settings = {
      Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandlePowerKey = "ignore";
      };
    };
  };

  modules = {
    hardware.nvidia.enable = false;

    networking = {
      mihomo-client.enable = true;
      tailscale.enable = true;
    };

    kernel = {
      fhs.enable = true;
      journald.enable = true;
      logind.enable = true;
      ntp.enable = true;
      openssh.enable = true;
      security-server.enable = true;
      vm.enable = true;
    };

    infra = {
      avahi.enable = false;
      guix.enable = false;
      btrbk.enable = false;
      nix-tools.enable = true;
    };

    systemd.manager.watchdog = {
      # homelab 机器也偏无人值守，启用 systemd Manager watchdog 作为死机自愈兜底。
      # 若将来需要按硬件单独调 Runtime/Reboot/KExec 超时，直接在该 host 调整参数即可。
      enable = true;
    };

    # 私网 homelab：显式关闭内置防火墙
    security.enableFirewall = false;
  };

  # system.stateVersion 由 inventory 注入，统一管理升级锚点
  system.stateVersion = lib.mkDefault stateVersion;
}
