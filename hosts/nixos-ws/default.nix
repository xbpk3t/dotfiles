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
    # 启用 NetworkManager 自动管理网络接口
    networkmanager.enable = true;
    useDHCP = false;

    # NetworkManager 使用 systemd-resolved 处理 DNS
    networkmanager.dns = "systemd-resolved";

    # DNS 配置
    inherit nameservers;
  };

  # 确保 systemd-resolved 正确启用
  services.resolved = {
    enable = true;
    fallbackDns = nameservers;
  };

  # Desktop Shell 配置
  # 使用 modules.desktop.shell 模块来管理 shell 服务
  # 注意：NixOS 和 home-manager 的配置需要保持一致
  modules.desktop.shell = {
    # Noctalia - 设置为 false 以禁用
    noctalia.enable = false;

    # DMS - 设置为 true 以启用
    dms.enable = true;
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

  # Allow unfree packages for nvidia drivers
  nixpkgs.config.allowUnfree = true;

  # Set system state version
  system.stateVersion = "24.11";

  # NetBird VPN client (enabled by default in module)
  # All configuration is handled in modules/nixos/base/networking/netbird.nix
  # To disable: modules.networking.netbird.client.enable = false;

  # Sing-box proxy service
  # Configuration file must be at /etc/sing-box/config.json
  modules.networking.singbox.enable = true;
}
