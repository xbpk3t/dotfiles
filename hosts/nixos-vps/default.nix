{myvars, ...}:
#############################################################
#
#  nixos-ws - NixOS Workstation
#
#############################################################
let
  hostName = "nixos-vps";

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

  # Shared boot configuration
  boot = {
    # Shared kernel modules
    initrd.kernelModules = [];
    kernelModules = [];
    extraModulePackages = [];
  };

  # Shared file systems configuration
  fileSystems = {};

  # Shared swap configuration
  swapDevices = [];

  # Shared system state version
  # Note: This should be host-specific and is kept here as an example
  # In practice, system.stateVersion should be set in host-specific configuration
  # system.stateVersion = "24.05";

  # 确保 systemd-resolved 正确启用
  services.resolved = {
    enable = true;
    fallbackDns = nameservers;
  };

  # Set system state version
  system.stateVersion = "24.11";
}
