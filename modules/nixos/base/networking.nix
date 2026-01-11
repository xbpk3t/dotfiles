{
  config,
  lib,
  ...
}: let
  inherit (lib) mkMerge mkIf;
  isServer = config.modules.roles.isServer;
  # hostMeta 由 colmena 注入（lib/mkColmenaRole.nix），
  # 用于统一生成动态 hostName / DERP 域名等派生值。
  # 若没有注入（非 colmena 或未配置），保持现有行为不变。
  hostMeta = config._module.args.hostMeta or null;
in {
  # 默认启用“动态 hostName”：只要 colmena 注入了 hostMeta，就覆盖系统 hostName。
  # 这样每台 VPS 都能拿到唯一主机名，避免多机同名导致域名/证书冲突。
  networking = mkIf (hostMeta != null) {
    hostName = hostMeta.hostName;
  };
  # Network performance optimization
  # These are safe, widely-used network optimization parameters
  # that improve performance for both desktop and server environments
  # Use an NTP server located in the mainland of China to synchronize the system time
  networking.timeServers = [
    "ntp.aliyun.com" # Aliyun NTP Server
    "ntp.tencent.com" # Tencent NTP Server
  ];

  # NixOS 默认启用的是 systemd-timesyncd，这是 systemd 自带的一个轻量 SNTP（简化版 NTP）客户端，用来自动同步时间。NixOS 的 NTP 文档里明确说默认 NTP 实现是 systemd-timesyncd。
  # https://mynixos.com/nixpkgs/options/services.chrony

  # 想让这台机器 给别的机器当时间服务器（NTP/NTS server）
  #对时间精度有比较高的要求（日志对齐、多机事务、金融、监控等）：需要 毫秒甚至更优
  #机器 经常睡眠/断网/虚拟化环境多，网络质量比较复杂
  # ➜ 更推荐 chrony：功能更强、精度更高、对「不稳定环境」适配更好。
  # 「懒得折腾 + 一般用途」：留在 NixOS 默认的 systemd-timesyncd ✅
  #「要精度、要 NTS、要当时间服务器」：换到 chrony ✅
  services.timesyncd.enable = lib.mkDefault true;

  # dynamically update /etc/hosts for testing
  # Note that changes made in this way will be discarded when switching configurations.
  environment.etc.hosts.mode = "0644";

  # Network and system performance optimization
  # 基线：安全通用；服务器分支：更激进的网络与内存调优
  boot.kernel.sysctl = mkMerge [
    {
      # File system settings
      # Increase system-wide file descriptor limit
      "fs.file-max" = 67108864;

      # Network core settings
      # Increase connection backlog for better concurrency
      "net.core.somaxconn" = 65536;

      # TCP optimization
      # Use BBR congestion control algorithm (modern, efficient)
      "net.ipv4.tcp_congestion_control" = "bbr";
      # Enable TCP window scaling for better throughput
      "net.ipv4.tcp_window_scaling" = 1;
      # Don't use slow start after idle periods
      "net.ipv4.tcp_slow_start_after_idle" = 0;

      # Virtual memory optimization
      # Reduce swap usage to improve performance
      "vm.swappiness" = 10;
      # More aggressive cache pressure management
      "vm.vfs_cache_pressure" = 250;
    }

    (mkIf isServer {
      # Server tuning: 更激进的 buffer/queue/ECN/overcommit，适合高并发高带宽；小内存或旧网络设备请谨慎

      # # VM optimization
      #vm.swappiness = 10
      #vm.dirty_ratio = 15
      #vm.dirty_background_ratio = 5
      #vm.overcommit_memory = 1
      #vm.min_free_kbytes = 65536
      #vm.overcommit_ratio = 100
      #vm.vfs_cache_pressure = 30
      #
      ## Core network parameters
      #net.core.default_qdisc = fq
      #net.core.rmem_max = 67108864
      #net.core.wmem_max = 33554432
      #net.core.netdev_max_backlog = 500000
      #net.core.somaxconn = 4096
      #
      ## TCP parameter optimization (for CN2 GIA + single-thread optimization)
      #net.ipv4.tcp_congestion_control = bbr
      #net.ipv4.tcp_mem = 104857600 943718400 1073741824
      #
      ## Single-thread optimization: increase initial and maximum windows
      #net.ipv4.tcp_rmem = 8192 262144 134217728
      #net.ipv4.tcp_wmem = 8192 131072 67108864
      #
      #net.ipv4.tcp_max_syn_backlog = 8192
      #net.ipv4.tcp_tw_reuse = 1
      #net.ipv4.tcp_fin_timeout = 30
      #net.ipv4.tcp_keepalive_time = 1200
      #net.ipv4.tcp_keepalive_probes = 9
      #net.ipv4.tcp_keepalive_intvl = 75
      #net.ipv4.tcp_slow_start_after_idle = 0
      #net.ipv4.tcp_no_metrics_save = 1
      #net.ipv4.tcp_mtu_probing = 1
      #net.ipv4.tcp_window_scaling = 1
      #net.ipv4.tcp_sack = 1
      #net.ipv4.tcp_timestamps = 1
      #net.ipv4.ip_local_port_range = 1024 65535
      #
      ## Single-thread performance critical parameters
      #net.ipv4.tcp_pacing_ca_ratio = 120
      #net.ipv4.tcp_pacing_ss_ratio = 200
      #net.ipv4.tcp_notsent_lowat = 16384
      #net.core.netdev_budget = 600
      #net.core.netdev_budget_usecs = 5000
      #
      ## BBR single-thread optimization parameters
      #net.ipv4.tcp_adv_win_scale = 1
      #net.ipv4.tcp_moderate_rcvbuf = 1
      #
      ## CPU affinity and interrupt optimization
      #kernel.sched_autogroup_enabled = 0
      #kernel.numa_balancing = 0
      #net.core.rps_sock_flow_entries = 32768

      # Network core settings
      # 使用 fq qdisc；老内核可能不支持
      "net.core.default_qdisc" = "fq";
      # 提高 RX backlog，适合高 PPS；弱网卡可能增加 IRQ 负载
      "net.core.netdev_max_backlog" = 32768;
      # 放宽 socket optmem，提升高 PPS 处理能力
      "net.core.optmem_max" = 262144;
      # 提高 TCP recv buffer 上限，长肥链路吞吐更好
      "net.core.rmem_max" = 33554432;
      "net.core.rmem_default" = 1048576;
      # 提高 TCP send buffer 上限
      "net.core.wmem_max" = 33554432;
      "net.core.wmem_default" = 1048576;

      # TCP settings
      # 更宽的自适应 rmem/wmem，适配高 BDP 链路
      "net.ipv4.tcp_rmem" = "16384 1048576 33554432";
      "net.ipv4.tcp_wmem" = "16384 1048576 33554432";
      # 缩短 FIN timeout，加快连接回收
      "net.ipv4.tcp_fin_timeout" = 25;
      # Keepalive 间隔（长连接多可适当减小）
      "net.ipv4.tcp_keepalive_time" = 1200;
      "net.ipv4.tcp_keepalive_probes" = 7;
      "net.ipv4.tcp_keepalive_intvl" = 30;
      # 提高 orphan 上限，高并发下防早丢；注意内存占用
      "net.ipv4.tcp_max_orphans" = 819200;
      # 放大 SYN backlog，应对突发连接
      "net.ipv4.tcp_max_syn_backlog" = 20480;
      # 放大 TIME_WAIT 桶；小内存机器注意 RAM 消耗
      "net.ipv4.tcp_max_tw_buckets" = 1440000;
      # 放宽 TCP memory 水位，适合高带宽，需监控内存
      "net.ipv4.tcp_mem" = "65536 1048576 33554432";
      # 开启 MTU probing，复杂链路更稳；少数 middlebox 可能不兼容
      "net.ipv4.tcp_mtu_probing" = 1;
      # 发送前低水位，提升大吞吐
      "net.ipv4.tcp_notsent_lowat" = 32768;
      # 略收紧重试次数
      "net.ipv4.tcp_retries2" = 8;
      # 启用 SACK/DSACK
      "net.ipv4.tcp_sack" = 1;
      "net.ipv4.tcp_dsack" = 1;
      # 窗口缩放偏置
      "net.ipv4.tcp_adv_win_scale" = -2;
      # 开启 ECN；好链路收益，坏 middlebox 需依赖 fallback
      "net.ipv4.tcp_ecn" = 1;
      "net.ipv4.tcp_ecn_fallback" = 1;
      # 开启 SYN cookies 防 SYN flood
      "net.ipv4.tcp_syncookies" = 1;
      # 偏向低时延
      "net.ipv4.tcp_low_latency" = 1;

      # UDP settings
      # 放宽 UDP memory 上限，适合高吞吐
      "net.ipv4.udp_mem" = "65536 1048576 33554432";

      # Virtual memory (VM) settings
      # 保留更多 free kbytes，降低压力抖动
      "vm.min_free_kbytes" = 65536;
      # 写脏页比例，提升写性能，需监控内存
      "vm.dirty_ratio" = 20;
      # 严格 overcommit，稳定性更高，小内存可能更早 OOM
      "vm.overcommit_memory" = 2;
      "vm.overcommit_ratio" = 100;

      # Network configuration
      # 严格 rp_filter，防多宿主场景 IP spoofing
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.conf.all.rp_filter" = 2;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      # 放大 neighbor table 上限，适合大量并发 peers
      "net.ipv4.neigh.default.gc_thresh1" = 512;
      "net.ipv4.neigh.default.gc_thresh2" = 2048;
      "net.ipv4.neigh.default.gc_thresh3" = 16384;
      "net.ipv4.neigh.default.gc_stale_time" = 60;
      # ARP announce 调优，减少 ARP 混乱/欺骗
      "net.ipv4.conf.default.arp_announce" = 2;
      "net.ipv4.conf.lo.arp_announce" = 2;
      "net.ipv4.conf.all.arp_announce" = 2;

      # UNIX domain sockets
      # 提升本地 dgram queue 长度，承载突发 IPC
      "net.unix.max_dgram_qlen" = 256;

      # Kernel settings
      # panic 后 1s 自动重启，减少宕机时间
      "kernel.panic" = 1;
    })
  ];
}
