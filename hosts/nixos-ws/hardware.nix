{
  config,
  lib,
  modulesPath,
  inputs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    # Lenovo XiaoXinAir-14IIL 2020 is similar to IdeaPad series with Intel 10th gen
    # Using common laptop optimizations since there's no specific profile
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    # NOTE: lenovo-ideapad-14imh9 模块包含一个 workaround-reset-xhci-driver 服务
    # 该服务检查 Chicony 摄像头，但本机使用的是 Syntek 摄像头，导致服务失败
    # 因此暂时禁用该模块，只使用通用的 laptop 优化
    # inputs.nixos-hardware.nixosModules.lenovo-ideapad-14imh9
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" "rtsx_pci_sdmmc"];

  boot.initrd.kernelModules = [];

  boot.kernelModules = ["kvm-intel"];

  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e02a3254-7322-4932-a428-b3027575ff02";

    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2229-EDEE";

    fsType = "vfat";

    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking

  # (the default) this is the recommended approach. When using systemd-networkd it's

  # still possible to use this option, but it's recommended to use it in conjunction

  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.

  networking.useDHCP = lib.mkDefault true;

  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
