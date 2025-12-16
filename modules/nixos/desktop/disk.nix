{myvars, ...}: {
  # 启动菜单等待时间
  # boot.loader.timeout = lib.mkForce 10;

  # 1) 用内核 exFAT（非 fuse），保证 U 盘速度
  boot.supportedFilesystems = ["exfat"];

  # 终端 sudo 兼容（kitty/wezterm/foot 等）
  security.sudo.keepTerminfo = true;

  # 基础系统服务
  services = {
    # SSD TRIM
    fstrim.enable = true;

    # 磁盘健康监控（默认关闭，按需开启）
    smartd = {
      enable = true;
      autodetect = true;
      notifications.mail = {
        enable = true;
        recipient = "${myvars.mail}";
      };
    };
  };
}
