{
  lib,
  userMeta,
  ...
}:
#############################################################
#
#  nixos-usb - U 盘专属配置
#
#  针对「U 盘作为系统盘」的特殊性：
#  1. 保护闪存寿命：频繁写入目录 → tmpfs（内存）
#  2. 数据分区自动挂载（exFAT，Windows/macOS 也能读写）
#  3. 定时 GC 控制空间
#  4. GDM 自动登录（即插即用场景免输密码）
#
#############################################################
{
  # ── 0. Root 文件系统：跨机器用 partlabel，不写死 UUID ──
  # U 盘插到任何机器上，/dev/disk/by-partlabel/NIXOS_ROOT 都能解析到根分区
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/NIXOS_ROOT";
      fsType = "ext4";
      options = [ "noatime" ];
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/ESP";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    "/var/log" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };
    "/var/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };

    "/mnt/data" = {
      device = "/dev/disk/by-partlabel/DATA";
      fsType = "exfat";
      options = [
        "noatime"
        "nofail" # 数据盘不在时不阻塞启动
      ];
    };
  };
  swapDevices = [ ]; # U 盘不用磁盘 swap（保护寿命，用 zram）

  boot = {
    # ── 1. 保护 U 盘寿命：频繁写入目录放内存 ──
    tmp.useTmpfs = true; # /tmp → tmpfs

    # ── 2. 数据分区自动挂载（exFAT）──
    supportedFilesystems = [ "exfat" ];
    kernelParams = [
      "usbcore.autosuspend=-1" # USB 设备不自动挂起（避免掉盘）
    ];
  };

  # ── 3. 定时 GC（U 盘空间宝贵，保留 7 天回滚）──
  nix.gc = {
    automatic = true;
    # mkForce：覆盖 nix-tools.nix 基线的 8d，U 盘用更激进的 7d
    options = lib.mkForce "--delete-older-than 7d";
  };

  services = {
    # ── 4. GDM 自动登录（即插即用）──
    displayManager.autoLogin = {
      enable = true;
      user = userMeta.username;
    };

    # ── 5. U 盘性能/寿命优化 ──
    fstrim.enable = true; # 支持 TRIM 的盘定期回收

    # 日志压缩 + 限量（U 盘空间宝贵）
    journald.extraConfig = ''
      Compress=yes
      SystemMaxUse=200M
      SystemKeepFree=100M
      MaxRetentionSec=7day
    '';
  };
}
