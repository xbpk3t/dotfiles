{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # VPS 通过 virtio 虚拟化，initrd 必须包含对应驱动才能挂载根文件系统。
  # Why 不依赖 nixos-facter：此 VPS 硬件固定不变，手写更直接；也让 nixos-anywhere
  # 首次刷机不受 facter report 缺失影响（否则 initrd 无磁盘驱动 → boot 卡 NIXOS_ROOT）。
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "ahci"
    "xhci_pci"
    "sd_mod"
  ];

  boot.initrd.kernelModules = ["virtio_net"];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  networking.useDHCP = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
