{
  globals,
  lib,
  ...
}: let
  hostName = "nixos-homelab";
  inherit (globals.networking) nameservers;
in {
  imports = [
    ./hardware.nix
  ];

  networking = {
    inherit hostName;
    useNetworkd = true; # 改用 systemd-networkd，更轻量
    networkmanager.enable = false;
    useDHCP = true; # 由 hardware.nix 的接口/或 networkd profiles 提供 DHCP
    # 重要：避免 /etc/resolv.conf 指向 127.0.0.53（stub）
    # k3s 的 CoreDNS 默认 forward 到 /etc/resolv.conf；若是 stub 会在 Pod 内超时
    useHostResolvConf = lib.mkForce false;
    inherit nameservers;
  };

  services.resolved = {
    enable = true;
    # NOTE: fallbackDns 已迁移到 settings.Resolve.FallbackDNS
    settings.Resolve.FallbackDNS = nameservers;
    # 重要：关闭本地 stub（127.0.0.53），避免集群 DNS 走到不可达的本地回环
    # settings = {
    #   DNSStubListener = "no";
    # };
  };

  # 重要：显式使用 systemd-resolved 的真实上游解析结果
  # Why：避免 /etc/resolv.conf 指向 stub-resolv.conf，导致 CoreDNS 解析超时
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
    # NOTE: 旧字段已迁移到 settings.Login.*
    settings.Login.HandleLidSwitch = "ignore";
    settings.Login.HandleLidSwitchDocked = "ignore";
    settings.Login.HandlePowerKey = "ignore";
  };

  modules = {
    hardware.nvidia.enable = false;

    networking = {
      singbox.enable = true;
      tailscale.enable = true;
    };

    systemd.manager.watchdog = {
      # homelab 机器也偏无人值守，启用 systemd Manager watchdog 作为死机自愈兜底。
      # 若将来需要按硬件单独调 Runtime/Reboot/KExec 超时，直接在该 host 调整参数即可。
      enable = true;
    };

    homelab = {
      samba = {
        enable = true;
        shareName = "luck";
        sharePath = "/home/luck";
        user = "luck";
        # 这里没办法直接用 pwgen 动态生成密码（我不想把这个塞到sops里），所以直接设置为空串
        password = "";
        allowedLan = "192.168.71.0/24";
        # allowedTailscaleIp = "100.115.38.12/32";
        # 为了方便，调整为允许整个 tailnet 连接。不会有任何安全问题。
        # 只是放宽了你本机的本地防火墙/服务访问范围；但 Tailscale 能不能连上 取决于你的 tailnet ACL/SSH policy 和是否在同一个 tailnet。
        #   - 不在同一个 tailnet 的设备：根本不会有 100.64/10 的地址，也不会通过 Tailscale 直连 → 连不上。
        # - 在同一个 tailnet，但 ACL 不允许访问该设备/端口：即使你本机放开了网段 → 依然连不上。
        # - 在同一个 tailnet且 ACL 允许访问：那才会被你本机规则放行。
        allowedTailscaleIp = "100.64.0.0/10";
      };
    };

    # 私网 homelab：显式关闭内置防火墙
    security.enableFirewall = false;

    extra = {
      # 需要远程开发再开启；默认保持关闭即可在 host 覆写
      vscode-remote.enable = lib.mkDefault true;

      # k3s 控制面：只设置 enable/role，其它配置在模块内固化
      k3s = {
        enable = true;
        role = "server";
        # serverIP 由 inventory 注入，避免多处重复维护
        serverPort = 6443;
      };
    };
  };

  # system.stateVersion 保持当前主版本
  system.stateVersion = "24.11";
}
