{
  config,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

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

  # 通用微码更新策略：仅在允许可再分发固件时启用
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
