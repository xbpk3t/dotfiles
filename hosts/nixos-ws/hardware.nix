{
  pkgs,
  lib,
  modulesPath,
  mylib,
  ...
}: let
  facterReport = mylib.facter.reportPathForHost "nixos-ws";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

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

  networking.useDHCP = lib.mkForce true;

  # networking.interfaces.wlp0s20f3.useDHCP =  true;

  nixpkgs.hostPlatform = "x86_64-linux";
  services.fstrim.enable = true;

  # What：显式保留 laptop power policy。
  # Why：之前是通过 common-pc-laptop 隐式开启 TLP；现在改成直写，语义更清楚，也避免继续依赖笼统 profile。
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;

  # What：显式保留 Intel iGPU 的 user-space runtime。
  # Why：common-cpu-intel 不只做 microcode；它还会给 Intel iGPU 提供 media/compute runtime。
  #      这些不完全属于 facter 的覆盖范围，因此这里改成显式声明，避免 hybrid graphics 场景下视频解码能力回退。
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-compute-runtime
    vpl-gpu-rt
  ];
  hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
    intel-media-driver
  ];

  # What：交给 nixos-facter 的 report 驱动底层硬件事实。
  # Why：这里不再保留 initrd/kernel/microcode 的手写 fallback，优先保持配置清洁和单一数据源。
  hardware.facter.reportPath = facterReport;
}
