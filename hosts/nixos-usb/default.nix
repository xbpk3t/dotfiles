{
  globals,
  hostMeta,
  inputs,
  lib,
  mylib,
  pkgs,
  stateVersion,
  ...
}:
#############################################################
#
#  nixos-usb - Portable NixOS on a USB stick
#
#  跨机器便携桌面系统：插到任意 x86_64 机器上即可启动。
#  硬件策略：不写死任何硬件（无 facter、无 hardware.nix 快照），
#  全部交给内核 + udev 自动探测，铺大网保证兼容性。
#
#############################################################
let
  inherit (hostMeta) hostName;
  inherit (globals.networking) nameservers;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    ./usb.nix
    ./disko.nix
    (mylib.relativeToRoot "secrets/default.nix")
    (mylib.relativeToRoot "modules/nixos/kernel")
    (mylib.relativeToRoot "modules/nixos/desktop")
    (mylib.relativeToRoot "modules/nixos/infra/nix-tools.nix")
    (mylib.relativeToRoot "modules/nixos/infra/tailscale-client.nix")
    (mylib.relativeToRoot "modules/nixos/infra/mihomo-client.nix")
  ];

  # ── 引导：U 盘专属 ──
  # systemd-boot 装在 U 盘 EFI 分区；不碰宿主机的 UEFI 变量（安全）
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = false;
        efiSysMountPoint = "/boot";
      };
    };
    # 用最新内核：新硬件兼容性最好（USB 系统要面对各种未知机器）
    kernelPackages = pkgs.linuxPackages_latest;
    # U 盘启动关键驱动：initrd 必须能读 USB 存储
    initrd.availableKernelModules = [
      "usb_storage"
      "xhci_pci"
      "ehci_pci"
    ];
  };

  # ── 跨机器硬件：铺大网 ──
  hardware = {
    enableAllFirmware = true; # 所有可重分发固件（Wi-Fi/蓝牙/网卡）
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    cpu.amd.updateMicrocode = true;
    graphics.enable = true; # 开源驱动（Intel/AMD 通吃）
    bluetooth.enable = true;
  };

  # ── 网络：NetworkManager 适应不同网络环境 ──
  networking = {
    inherit hostName;
    useDHCP = false; # NetworkManager 自己管 DHCP
    networkmanager.enable = true;
    inherit nameservers;
  };

  # ── 桌面：GNOME（与工作站一致的体验）──
  services = {
    xserver.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    libinput.enable = true; # 触控板/触摸屏
    resolved.enable = true;
  };

  # ── 模块开关（复用仓库现有模块）──
  modules = {
    desktop = {
      gnome.enable = true;
      audio.enable = true;
      openssh-desktop.enable = true;
      power.enable = true;
      tuptime.enable = true;
      vm.enable = true;
    };
    kernel = {
      fhs.enable = true;
      journald.enable = true;
      logind.enable = true;
      ntp.enable = true;
      openssh.enable = true;
      security-server.enable = true;
      vm = {
        enable = true;
        forwardFilter.enable = true;
      };
    };
    networking = {
      # 代理：mihomo-client 走 tailnet 回自己 VPS 节点
      mihomo-client.enable = true;
      # tailscale：跨机器 SSH/deploy 的基础（tailnet IP 固定）
      tailscale.enable = true;
    };
  };

  system.stateVersion = lib.mkDefault stateVersion;
}
