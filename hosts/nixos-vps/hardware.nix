{
  modulesPath,
  mylib,
  ...
}: let
  facterReport = mylib.facter.reportPathForHost "nixos-vps";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  networking.useDHCP = true;
  nixpkgs.hostPlatform = "x86_64-linux";

  # What：交给 nixos-facter 的 report 驱动底层硬件事实。
  # Why：这里不再保留 initrd/kernel/microcode 的手写 fallback，避免“接了 facter 但旧样板还在”。
  hardware.facter.reportPath = facterReport;
}
