{myvars, ...}:
#############################################################
#
#  nixos-ws - NixOS Workstation
#
#############################################################
let
  hostName = "nixos-ws";

  # Following RNC pattern: dynamically inherit host-specific variables

  # Network configuration from vars/networking.nix
  inherit (myvars.networking) nameservers;
  # NetworkManager 自动管理，不需要网关和静态IP配置
in {
  imports = [
    # Include the results of the hardware scan
    ./hardware.nix
    ./nvidia.nix
  ];

  # Hostname & NetworkManager (GNOME Wi‑Fi 依赖 NM)
  networking = {
    inherit hostName;
    useDHCP = false;
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      # 默认使用 wpa_supplicant；若需要 iwd 后端可再开启：
      # wifi.backend = "iwd";
    };
    inherit nameservers;
  };

  # 确保 systemd-resolved 正确启用
  services.resolved = {
    enable = true;
    fallbackDns = nameservers;
  };

  # 禁用挂起/休眠/混合睡眠，仅阻断这些 target，不影响 systemctl poweroff 或桌面关机。
  # 为什么建议前两段都加
  #  - 只加第一段：阻止任何显式的 suspend/hibernate 调用，但如果GNOME/桌面或 logind 因“合盖、空闲超时、电源键”触发的是挂起动作，它仍会去拉起 suspend，结果被 systemd 拒绝 → 屏幕会黑一下或弹警告，体验不好；而且某些发行版会回退到其他动作，行为不确定。
  #  - 加上第二段（logind 层）后，直接把这些触发源改成 ignore，根本不再尝试挂起，既干净又可预期。
  #  - 如果你的机器是台式机，或确定不会合盖/空闲触发挂起，第一段单独用也能达到“不睡眠”的技术目标；只是出于“消除多余尝试、避免奇怪回退”的体验考虑，才推荐两段一起用。

  # 永不睡眠（回答用户关机疑问：只禁挂起/休眠，不影响 systemctl poweroff/桌面关机）
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  # logind 也屏蔽合盖/闲置触发挂起，避免出现“尝试挂起但被上面拒绝”的黑屏/提示；关机/重启仍正常
  # 忽略合盖、闲置和电源键触发的挂起，避免出现“尝试挂起但被拒绝”的黑屏/提示；若想让电源键关机，可把powerKey 改成 "poweroff"。
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    # idleAction = "ignore";
    # 若希望电源键关机可改为 "poweroff"；为防误触挂起这里默认忽略
    powerKey = "ignore";
  };

  # Boot configuration - Enable systemd-boot and disable GRUB
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    systemd-boot.enable = true;
    timeout = 10;
    # Explicitly disable GRUB to avoid conflicts
    grub.enable = false;
  };

  # 启用 nixos-container 容器支持
  boot.enableContainers = true;

  # NOTE: nixpkgs.config.allowUnfree is already set in genSpecialArgs (outputs/default.nix)
  # Do NOT set it here when using specialArgs.pkgs as it will be ignored and cause warnings

  # 切换到 GNOME（Wayland 默认），避免 greetd/hyprland 冲突
  modules.desktop = {
    gnome.enable = true;
  };

  # Set system state version
  system.stateVersion = "24.11";

  # NetBird VPN client (enabled by default in module)
  # All configuration is handled in modules/nixos/base/networking/netbird.nix
  # To disable: modules.networking.netbird.client.enable = false;

  # Sing-box proxy service
  # Configuration file must be at /etc/sing-box/config.json
  modules.networking.singbox.enable = true;

  # Allow user-space input remapping tools (xremap)
  # hardware.uinput.enable = true;

  # k3s Kubernetes with PAG stack
  # modules.k3s = {
  #   enable = true;
  #   role = "server";
  #   enablePAGStack = true;
  #   pagConfig = {
  #     prometheus.retention = "7d";
  #     prometheus.storageSize = "5Gi";
  #     grafana.adminPassword = "admin123";
  #     grafana.serviceType = "LoadBalancer";
  #   };
  # };

  #  modules.networking.netbird.enable = false;
}
