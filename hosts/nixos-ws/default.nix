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
    wayland.enable = false;
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
  hardware.uinput.enable = true;

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
