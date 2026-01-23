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

    homelab = {
      dokploy.enable = true;
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
        serverAddr = "https://100.81.204.63:6443";
      };
    };
  };

  # system.stateVersion 保持当前主版本
  system.stateVersion = "24.11";
}
