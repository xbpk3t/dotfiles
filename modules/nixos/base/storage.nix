{
  pkgs,
  lib,
  ...
}: {
  # 1) 用内核 exFAT（非 fuse），保证 U 盘速度
  boot.supportedFilesystems = ["exfat"];

  # 2) 自动挂载 & 设备集成（Thunar 依赖）
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true; # 开缩略图守护进程（会自动带上对应包）

  # 3) 安装 Thunar 及相关工具（注意 xfce 命名空间）
  environment.systemPackages = lib.mkAfter [
    pkgs.xfce.thunar
    pkgs.xfce.thunar-volman # U 盘等可移动设备的自动处理扩展
    pkgs.gvfs
    pkgs.exfatprogs # exFAT 工具（mkfs.exfat / fsck.exfat / exfatlabel）
    pkgs.usbutils # lsusb 等
    pkgs.pv # 传输进度（命令行时好用）
    # 可选：图形化分区/测速工具（类似 macOS“磁盘工具”）
    # pkgs.gnome-disk-utility
    # 可选：视频缩略图更丰富
    # pkgs.ffmpegthumbnailer
  ];
}
