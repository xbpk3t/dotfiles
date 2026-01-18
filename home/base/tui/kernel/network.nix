{
  lib,
  pkgs,
  ...
}: {
  # https://github.com/nicolaka/netshoot 参考该repo提供的一些
  home.packages = with pkgs;
    [
      # 网络工具 (excluding wget/curl which are in minimal)
      mosh
      fping
      inetutils
      # https://mynixos.com/nixpkgs/package/dig
      dig
      mtr

      gping # ping, but with a graph(TUI)
      #  doggo # DNS client for humans

      duf # Disk Usage/Free Utility - a better 'df' alternative
      #  du-dust # A more intuitive version of `du` in rust

      ncdu

      # rename
      rnr # https://github.com/ismaelgv/rnr

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

      # https://github.com/openwall/john/
      # https://mynixos.com/nixpkgs/package/john
      # used to crack passwords
      # john

      # https://github.com/bpftrace/bpftrace
      # BPF trace：内核动态跟踪
      # Not support Darwin
      # bpftrace

      # 监控当前运行的 BPF 程序
      # bpftop

      # BPF 可视化流量/包速率监控
      # bpfmon

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

      # https://github.com/zachwilke/netops
    ]
    # Linux-only tools; Darwin 上直接跳过，避免 hostPlatform 不可用的求值错误
    ++ lib.optionals stdenv.isLinux [
      # nexttrace 可视化路由跟踪工具
      nexttrace

      # wifi with TUI
      # https://github.com/pythops/impala
      # https://mynixos.com/nixpkgs/package/impala
      # 只有个人的minimal机器需要（VPS或者desktop都用不到）
      # impala（Wi‑Fi TUI），仅在 Linux 上可用
      impala
    ];

  # ncurses 的无线网卡监控工具
  # 带 capabilities 的 wrapper（setcap wrapper），让普通用户也能用到 wavemon 的一些需要特权的功能（不需要你再自己去折腾 setcap/wrapper）。
  # https://mynixos.com/nixpkgs/package/wavemon
  # https://mynixos.com/nixpkgs/option/programs.wavemon.enable
  # programs.wavemon.enable = pkgs.stdenv.isLinux;

  # TODO: trippy
  # https://mynixos.com/home-manager/options/programs.trippy
  # https://github.com/fujiapple852/trippy
}
