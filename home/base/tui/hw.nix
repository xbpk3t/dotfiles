{pkgs, ...}: {
  home.packages = with pkgs; [
    # ethtool 查看与配置网卡参数
    ethtool

    # pciutils 提供 lspci，查看 PCI 设备
    pciutils

    # usbutils 提供 lsusb，查看 USB 设备
    usbutils

    # hdparm 硬盘性能与参数工具
    hdparm

    # dmidecode 读取 SMBIOS/DMI 硬件信息
    dmidecode

    # parted 磁盘分区管理
    parted

    # https://github.com/ifd3f/caligula
    # 更强的 dd，用于制作 UEFI 启动盘
    caligula
  ];
}
