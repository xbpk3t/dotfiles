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

  # Hostname configuration - NetworkManager 自动管理
  networking = {
    inherit hostName;
    useDHCP = false;

    # 启用 IWD 守护进程，impala/iwctl 才能通过 D-Bus 控制 Wi-Fi
    wireless.iwd = {
      enable = true;
      settings = {
        # 让 iwd 自行管理 DHCP/路由/DNS，impala 才能完成握手后拿到网路
        General = {
          EnableNetworkConfiguration = true;
        };
        Network = {
          NameResolvingService = "systemd";
        };
      };
    };

    # 启用 NetworkManager 自动管理网络接口，并改用 IWD 作为 Wi-Fi backend
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      # 让 NetworkManager 不再接管 Wi-Fi 介面，避免和 iwd/impala 抢资源（否则在使用 impala 时，会报错 Operation Not Permitted）
      unmanaged = ["type:wifi"];
    };

    # DNS 配置
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

  modules.desktop.wayland.enable = true;

  # Set system state version
  system.stateVersion = "24.11";

  # NetBird VPN client (enabled by default in module)
  # All configuration is handled in modules/nixos/base/networking/netbird.nix
  # To disable: modules.networking.netbird.client.enable = false;

  # Sing-box proxy service
  # Configuration file must be at /etc/sing-box/config.json
  modules.networking.singbox.enable = true;

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
