{
  # ==================================================================
  # nixos-usb - U 盘分区方案（声明式，nixos-anywhere/disko 使用）
  #
  # 三区布局：
  #   ESP   : 512M vfat   → 引导（systemd-boot）
  #   root  : 系统（ext4，label=NIXOS_ROOT）
  #   DATA  : 数据（exFAT，跨 OS 读写，label=DATA）
  #
  # 设计要点：
  # - 不用 swap 分区（保护 U 盘寿命，系统用 zram）
  # - DATA 用 exFAT：Windows/macOS/Linux 都能读写，U 盘可当普通优盘用
  # - root/DATA 都用 partlabel 挂载，跨机器稳定
  #
  # 分区顺序（GPT）：
  #   [ESP 512M] [root 余量-2G] [DATA 最后 2G]
  # root 用 size = "100% - 2G" 表达式占满除 DATA 外的空间
  # ==================================================================
  disko.devices = {
    disk.main = {
      # 目标磁盘：U 盘设备名。安装时用 nixos-anywhere --disk 覆盖
      type = "disk";
      device = "/dev/disk/by-id/usb-xxxx"; # TODO: 替换为实际 U 盘 by-id
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "512M";
            type = "EF00";
            label = "ESP";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };

          root = {
            # 根分区：占满除 DATA 外的剩余空间
            # disko 支持 size 表达式："100% - 2G" 表示剩余全部减去 2G
            size = "100% - 2G";
            type = "8300";
            label = "NIXOS_ROOT";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "noatime"
                "nodiratime"
              ];
            };
          };

          data = {
            # 数据分区：最后 2G，exFAT
            size = "2G";
            type = "0700";
            label = "DATA";
            content = {
              type = "filesystem";
              format = "exfat";
              mountpoint = "/mnt/data";
              mountOptions = [ "nofail" ];
            };
          };
        };
      };
    };
  };

  # 运行时 fileSystems 已定义在 hosts/nixos-usb/usb.nix，disko 只负责分区/格式化
}
