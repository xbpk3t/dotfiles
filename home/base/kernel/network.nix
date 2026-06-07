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

      mosh
      fping

      # https://mynixos.com/nixpkgs/package/inetutils
      # 提供了 ftp(d), hostname, ifconfig, inetd, logger, ping, rcp, rexec(d), rlogin(d), rsh(d), syslogd, talk(d), telnet(d), tftp(d), traceroute, uucpd, and whois 这些cli
      # [2026-04-30] 注释掉该pkgs
      #  1. 大部分工具对你来说是废物甚至包袱
      #
      #  inetutils 提供的一堆东西里：
      #
      #  - ftp(d), telnet(d), rsh(d), rcp, rexec(d), talk(d), uucpd — 全是不安全/过时的协议，不该用
      #  - syslogd, inetd — macOS 用 launchd，不是这俩
      #  - hostname, ifconfig, logger, ping, whois — macOS 有原生 BSD 版，且行为更贴合 Darwin
      #
      #  为了一个 traceroute 拉了一堆几乎用不到的东西进来。
      #
      #  2. 在 macOS 上没带来额外价值
      #
      #  macOS 原生 /usr/sbin/traceroute 已经存在。inetutils 的 GNU   traceroute实现反而更弱（功能子集），你没有任何理由用它的版本覆盖系统原生。
      #
      #  3. 造成二进制冲突，锁死其他选择
      #
      #  如果以后想装独立的 traceroute 包（nixpkgs 那个），会和 inetu bin/traceroute 上冲突。Nix bu对这种同名冲突是直接报错的，两者不能共存。
      #
      #  4. Linux 侧已有更好的替代
      #
      #  你 Linux-only 段已经装了 iputils（提供 tracepath），加上独立traceroute 包也比 inetutils 的 traceroute 完善得多。
      #
      #  ---
      #  结论：删掉 inetutils，把 traceroute 加到 Linux-only 段。
      # inetutils

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

      # https://github.com/GyulyVGC/sniffnet
      # https://mynixos.com/nixpkgs/package/sniffnet
      # 仅作记录，暂不打算安装。
      # what: Sniffnet 是个GUI，“网络仪表盘”，侧重易用的可视化监控、地理位置识别和应用进程关联。
      # programs.sniffnet 必须放到 modules/nixos 里，因为依赖了 NixOS 特有的 security.wrappers 机制来分配内核特权
      # 还有什么我可能不知道的相关点？1. NixOS 下可能因沙盒限制看不到进程名；2. 它支持导出 .pcap 配合 Wireshark 联动；3. Rust GUI 可能存在字体渲染导致的“豆腐块”报错。

      # [2026-05-27] 这个 rustnet 完全是 sniffnet 的上位替代。移除掉【sniffnet】
      # 如果基于以下这些coder更常用的需求，且想要TUI而非GUI，应该直接选择rustnet
      # 想按进程、连接状态、SNI、协议、端口精细过滤
      # 想分析 TCP 重传、乱序、连接生命周期
      # 想导出带进程上下文的 PCAP 再进 Wireshark
      # [Vincent Logic | 信号＞噪音 on X: "发现个终端里的网络监控神器！ RustNet，在终端里就能实时监控所有网络连接，哪个进程在偷偷传数据、服务器被谁连了，一眼看清。 最爽的是能看到每个连接对应的应用程序，这点 Wireshark 都做不到。SSH 连服务器直接看，不用搞 X11 转发。 界面分四块： - 总览：所有连接列表 + 实时流量 - https://t.co/l4GGKuJuXv" / X](https://x.com/VincentLogic/status/2053454574888071242)
      # https://github.com/domcyrus/rustnet
      # https://mynixos.com/nixpkgs/package/rustnet
      rustnet
    ];

  # ncurses 的无线网卡监控工具
  # 带 capabilities 的 wrapper（setcap wrapper），让普通用户也能用到 wavemon 的一些需要特权的功能（不需要你再自己去折腾 setcap/wrapper）。
  # https://mynixos.com/nixpkgs/package/wavemon
  # https://mynixos.com/nixpkgs/option/programs.wavemon.enable
  # programs.wavemon.enable = pkgs.stdenv.isLinux;

  #  programs.mtr = {
  #    enable = pkgs.stdenv.isLinux;
  #  };

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

  # https://mynixos.com/nixpkgs/package/traceroute
  # https://mynixos.com/nixpkgs/option/programs.traceroute.enable
}
