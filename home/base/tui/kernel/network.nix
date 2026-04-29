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
      # https://mynixos.com/nixpkgs/package/dnslookup
      # https://mynixos.com/nixpkgs/package/whois
      dig

      # https://mynixos.com/nixpkgs/package/netperf

      # ping, but with a graph(TUI)
      gping
      #  doggo # DNS client for humans

      duf # Disk Usage/Free Utility - a better 'df' alternative
      #  du-dust # A more intuitive version of `du` in rust

      # https://mynixos.com/nixpkgs/package/mtr
      # 同时支持 linux, darwin, windows
      mtr

      ncdu

      # rename
      rnr # https://github.com/ismaelgv/rnr

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

      # https://mynixos.com/nixpkgs/package/websocat
      websocat

      # iperf3
    ]
    # Linux-only tools; Darwin 上直接跳过，避免 hostPlatform 不可用的求值错误
    ++ lib.optionals stdenv.isLinux [
      # https://mynixos.com/nixpkgs/package/iputils
      # - arping: send ARP REQUEST to a neighbour host
      # - clockdiff: measure clock difference between hosts
      # - ping: send ICMP ECHO_REQUEST to network hosts
      # - tracepath: traces path to a network host discovering MTU along this path.
      iputils

      # https://mynixos.com/nixpkgs/package/iproute2
      # nstat
      iproute2

      # nexttrace 可视化路由跟踪工具
      nexttrace

      # ethtool 查看与配置网卡参数
      # https://mynixos.com/nixpkgs/package/ethtool
      ethtool

      # wifi with TUI
      # https://github.com/pythops/impala
      # https://mynixos.com/nixpkgs/package/impala
      # 只有个人的minimal机器需要（VPS或者desktop都用不到）
      # impala（Wi‑Fi TUI），仅在 Linux 上可用
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
    ];

  # ncurses 的无线网卡监控工具
  # 带 capabilities 的 wrapper（setcap wrapper），让普通用户也能用到 wavemon 的一些需要特权的功能（不需要你再自己去折腾 setcap/wrapper）。
  # https://mynixos.com/nixpkgs/package/wavemon
  # https://mynixos.com/nixpkgs/option/programs.wavemon.enable
  # programs.wavemon.enable = pkgs.stdenv.isLinux;

  # MAYBE: trippy. 感觉可能也没啥用，之后再评估吧
  # https://mynixos.com/home-manager/options/programs.trippy
  # https://github.com/fujiapple852/trippy

  # https://mynixos.com/nixpkgs/options/programs.mtr
  #  programs.mtr = {
  #    enable = pkgs.stdenv.isLinux;
  #  };

  # https://mynixos.com/nixpkgs/options/services.iperf3
  #你说得没错，`iperf3` 本质上确实是一个命令行工具（CLI）。但之所以在 NixOS 或其他 Linux 发行版中存在 **`services.iperf3`** 这样的守护进程（Daemon）配置，主要是为了方便进行**持续性**和**自动化**的网络测试。
  #
  #以下是为什么要把它作为“服务”运行的几个核心原因：
  #
  #---
  #
  #### 1. 免去手动开启 Server 端
  #`iperf3` 的工作模式是 **Client-Server** 架构。当你想要测试网络带宽时：
  #* **普通 CLI 用法：** 你必须先 SSH 登录到远程机器，手动输入 `iperf3 -s` 开启监听，然后再回到本地机器运行客户端测试。
  #* **Service 用法：** 远程机器启动时就自动运行 `iperf3 -s`。你随时随地想测就测，不需要额外操作服务器。
  #
  #### 2. 自动化监控与集成
  #如果你在维护一个集群（比如 Kubernetes 节点或数据中心服务器），你可能需要：
  #* **定时任务：** 每天凌晨自动跑一次带宽测试，记录链路质量。
  #* **Prometheus 监控：** 配合 Exporter 抓取 `iperf3` 的输出，将网络吞吐量绘制在 Grafana 仪表盘上。
  #作为服务运行，可以确保测试环境始终就绪，且能通过 [systemd](https://mynixos.com/nixpkgs/options/services) 进行日志管理和状态监控。
  #
  #### 3. 安全与权限管理
  #通过 NixOS 的 `services.iperf3` 配置，你可以更优雅地处理安全问题：
  #* **[openFirewall](https://mynixos.com/nixpkgs/option/services.iperf3.openFirewall)**：在 NixOS 中，只要设为 `true`，系统会自动帮你打开对应的防火墙端口（默认 5201），省去了手动配置 `networking.firewall` 的麻烦。
  #* **[authorizedUsersFile](https://mynixos.com/nixpkgs/option/services.iperf3.authorizedUsersFile)**：可以配置用户验证文件，防止任何人都能连接你的服务器跑流量，避免带宽被恶意占满。
  #* **[bind](https://mynixos.com/nixpkgs/option/services.iperf3.bind)**：可以将服务限制在特定的内网 IP 上，而不是暴露在公网。
  #
  #### 4. 资源限制 (Affinity/Priority)
  #作为系统服务，你可以利用 `systemd` 的特性来限制它的优先级。
  #* 例如使用 **[affinity](https://mynixos.com/nixpkgs/option/services.iperf3.affinity)** 将 `iperf3` 绑定到特定的 CPU 核心，确保高负载测试时不会干扰到服务器上运行的其他核心业务进程。

  #**总结：**
  #CLI 版本适合“临时测一下”，而 **Service 版本** 则是为了把服务器变成一个“永久的测试基准点”。对于需要频繁排查网络问题的运维人员来说，这几乎是标配。
}
