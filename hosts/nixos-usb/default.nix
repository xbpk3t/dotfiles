{
  globals,
  lib,
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
  hostName = "nixos-usb";
  inherit (globals.networking) nameservers;
in
{
  imports = [
    ./usb.nix
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

  # ── 桌面：GNOME（与 nixos-ws 一致的体验）──
  services = {
    xserver.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    libinput.enable = true; # 触控板/触摸屏
    pipewire.enable = true; # 音频
    openssh.enable = true; # deploy-rs 需要
    resolved.enable = true;
  };

  # ── 输入法：fcitx5（与 nixos-ws 一致）──
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-pinyin-zhwiki
      ];
      settings = {
        inputMethod = {
          GroupOrder = {
            "0" = "Default";
          };
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "pinyin";
          };
          "Groups/0/Items/0" = {
            Name = "keyboard-us";
            Layout = "";
          };
          "Groups/0/Items/1" = {
            Name = "pinyin";
            Layout = "";
          };
        };
      };
    };
  };
  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  # ── 模块开关（复用仓库现有模块）──
  modules = {
    desktop = {
      gnome.enable = true;
    };
    networking = {
      # 代理：singbox 走 tailnet 回自己 VPS 节点
      singbox.enable = true;
      # tailscale：跨机器 SSH/deploy 的基础（tailnet IP 固定）
      tailscale.enable = true;
    };
  };

  system.stateVersion = lib.mkDefault stateVersion;
}
