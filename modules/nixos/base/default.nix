{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  environment.systemPackages = with pkgs; [
    # ethtool 查看与配置网卡参数
    # ethtool

    # pciutils 提供 lspci，查看 PCI 设备
    # pciutils

    # usbutils 提供 lsusb，查看 USB 设备
    # usbutils

    # hdparm 硬盘性能与参数工具
    # hdparm

    # dmidecode 读取 SMBIOS/DMI 硬件信息
    # dmidecode

    # parted 磁盘分区管理
    # parted

    # https://github.com/ifd3f/caligula
    # 更强的 dd，用于制作 UEFI 启动盘
    # caligula

    # 系统调用跟踪
    # Not support darwin
    # strace

    # 库调用跟踪
    # Not support darwin
    # ltrace

    # 查看进程打开的文件
    lsof

    # 系统性能监控工具集
    # sysstat

    # 磁盘与进程 I/O 监控
    # iotop-c

    # 网络流量监控
    # iftop

    # 全面系统性能监视（CPU/内存/磁盘/网络）
    # nmon

    # 压测与基准测试
    # sysbench

    # 杀进程、进程树等常用进程工具合集
    # psmisc

    # 进程信息查看（比 ps 更友好）
    procs

    # 实用工具集（ts 等小工具）
    moreutils
  ];
}
