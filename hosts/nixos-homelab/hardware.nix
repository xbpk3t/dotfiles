{
  lib,
  modulesPath,
  mylib,
  ...
}: let
  facterReport = mylib.facter.reportPathForHost "nixos-homelab";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # What：即便切到 facter，disk layout 仍然保留在 host 配置里。
  # Why：fileSystems / swap 更接近安装结果与运维约束，不适合交给自动探测动态漂移。
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
  networking.useDHCP = lib.mkForce true;
  nixpkgs.hostPlatform = "x86_64-linux";
  services.fstrim.enable = true;

  # What：交给 nixos-facter 的 report 驱动底层硬件事实。
  # Why：这里不再保留 initrd/kernel/microcode 的手写 fallback，保持 hardware.nix 尽量薄。
  hardware.facter.reportPath = facterReport;
}
