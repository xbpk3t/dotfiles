{
  lib,
  pkgs,
  ...
}:
{
  # https://github.com/nicolaka/netshoot 参考该repo提供的一些
  home.packages =
    with pkgs;
    [
      # 网络工具 (excluding wget/curl which are in minimal)

      fping

      dig

      # https://mynixos.com/nixpkgs/package/dnslookup
      # DNS 排错工具，比 dig/host 更直观的输出
      dnslookup

      # ping, but with a graph(TUI)
      gping
      #  doggo # DNS client for humans

      duf # Disk Usage/Free Utility - a better 'df' alternative
      #  du-dust # A more intuitive version of `du` in rust

      # 同时支持 linux, darwin, windows
      trippy

      ncdu

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

      # 网络抓包与 TLS 调试 — 从 home/core/infra/networking.nix 迁入
      tcpdump
      openssl

      # SSH 文件传输 — 从 home/base/devops/ssh.nix 迁入
      trzsz-ssh

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
      # vidir
      moreutils

      # https://github.com/zachwilke/netops

      # https://mynixos.com/nixpkgs/package/netcat
      #
      # 类似 nc -zv dokploy-postgres 5432 这种命令
      #
      #
      # 想要最“现代/通用”的功能集合（尤其是 TLS） → 选 netcat（LibreSSL 实现）：它直接把 TLS 当一等公民（-c 开 TLS + 一堆证书/校验选项）。
      # - 重点：带 TLS 支持（可直接用参数启用 TLS/证书相关选项），更适合测试 HTTPS/mTLS 之类场景
      # - 同时保留常见的 TCP/UDP 连接、监听、端口探测等基础 netcat 能力
      # - 如果你希望 “一个工具既能测明文端口也能测 TLS”，优先选它
      netcat

      websocat

      # https://mynixos.com/nixpkgs/package/tcpflow
      # TCP 流量记录器，按连接拆分 pcap
      tcpflow

      # iperf3

    ]
    # Linux-only tools; Darwin 上直接跳过，避免 hostPlatform 不可用的求值错误
    ++ lib.optionals stdenv.isLinux [
      # - arping: send ARP REQUEST to a neighbour host
      # - clockdiff: measure clock difference between hosts
      # - ping: send ICMP ECHO_REQUEST to network hosts
      # - tracepath: traces path to a network host discovering MTU along this path.
      iputils

      nftables
      iproute2

      nexttrace

      ethtool

      impala

      # https://mynixos.com/nixpkgs/package/netcat-openbsd
      #
      # 想要一个“传统网络瑞士军刀”，带代理/UNIX socket/扫描，但不带 TLS → netcat-openbsd（Debian port 那支）。
      # - 重点：更接近多数 Linux 发行版里常见的 “nc” 行为与参数习惯（脚本兼容性通常更稳）
      # - 支持常见 TCP/UDP、端口扫描(-z)、代理(-x/-X)、UNIX socket(-U) 等
      # - 一般不主打/不提供内置 TLS（需要 TLS 时另用 openssl s_client 或改用 LibreSSL 版 netcat）
      # - 如果你主要做 “端口连通性/代理/UNIX socket 调试”，选它很合适
      # What：避免与 netcat（LibreSSL）产生 nc 手册冲突。
      # Why：同时安装 netcat + netcat-openbsd 会在 home-manager buildEnv 冲突（nc.1.gz）。
      # netcat-openbsd

      rustnet
    ]
    ++ lib.optionals pkgs.stdenv.isLinux (
      with pkgs;
      [
        # https://www.wireshark.org/
        # 正如 modules/wireshark 所说，在 darwin/nixos 拆分安装 wireshark
        # wireshark

        tshark

        ngrep
      ]
    );
}
