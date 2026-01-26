{lib}: let
  inherit (lib) max min;

  clamp = lo: hi: x:
    max lo (min hi x);
  roundUp = x: align: ((x + align - 1) / align) * align;
  bdpBytes = bwMbps: rttMs: bwMbps * rttMs * 125;

  modeTable = {
    steady = {
      factorNum = 1;
      factorDen = 1;
      capPct = 2;
      backlogMult = 1;
    };
    balanced = {
      factorNum = 2;
      factorDen = 1;
      capPct = 4;
      backlogMult = 2;
    };
    performance = {
      factorNum = 3;
      factorDen = 1;
      capPct = 8;
      backlogMult = 3;
    };
    aggressive = {
      factorNum = 4;
      factorDen = 1;
      capPct = 12;
      backlogMult = 4;
    };
  };

  defaults = {
    # Server tuning: 更激进的 buffer/queue/ECN/overcommit，适合高并发高带宽；小内存或旧网络设备请谨慎

    #

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
    #
    #
    # [2026-01-20] 从 2 -> 1
    # 给homelab做rebuild时，返回 error: unable to fork: Cannot allocate memory
    # 查了一下 commit limit 不够 导致的拒绝分配，而不是物理内存不足。
    # - 机器 vm.overcommit_memory=2（严格模式）
    # - 当前 Committed_AS 很接近 CommitLimit
    # - 当 Nix 构建需要 fork 或分配大量虚拟内存时被拒绝
    #  这不是“空闲内存不足”，而是 commit 配额不足。
    "vm.overcommit_memory" = 1;
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
  };

  # Configuration
  #
  # mode: 默认使用 性能模式
  # cc: bbr
  # qdisc: cake
  #
  #
  mkSysctl = {
    bwMbps,
    rttMs,
    memGiB,
    mode ? "performance",
    cc ? "bbr",
    qdisc ? "cake",
    cpuCores ? null,
  }: let
    m = modeTable.${mode} or modeTable.balanced;
    memBytes = memGiB * 1024 * 1024 * 1024;
    bdp = bdpBytes bwMbps rttMs;
    scaledBdp = (bdp * m.factorNum) / m.factorDen;
    capBytes = (memBytes * m.capPct) / 100;
    rounded = roundUp scaledBdp 4096;
    minBuf = 1024 * 1024;
    bufMax = max minBuf (min rounded capBytes);

    # 重要：net.core.* 与 tcp_* 的 buffer 上限保持一致，避免 autotune 不稳定
    rmemMax = bufMax;
    wmemMax = bufMax;

    rmemDefault = defaults."net.core.rmem_default";
    wmemDefault = defaults."net.core.wmem_default";

    tcpRmem = "16384 ${toString rmemDefault} ${toString rmemMax}";
    tcpWmem = "16384 ${toString wmemDefault} ${toString wmemMax}";

    # 重要：保留最小 free kbytes，避免内存紧张时频繁抖动
    minFree = clamp 65536 524288 (memGiB * 4096);

    somaxconn =
      if cpuCores == null
      then defaults."net.core.somaxconn" or 65536
      else clamp 4096 65535 (cpuCores * 512);

    synBacklog =
      if cpuCores == null
      then defaults."net.ipv4.tcp_max_syn_backlog" or 20480
      else clamp 8192 262144 (cpuCores * 1024);

    # 重要：PPS 高时适度放大 netdev backlog，但需谨慎防止软中断压力上升
    netdevBacklog = clamp 2000 32768 (2000 + bwMbps * m.backlogMult * 2);
  in
    defaults
    // {
      "vm.min_free_kbytes" = minFree;

      "net.core.default_qdisc" = qdisc;
      "net.ipv4.tcp_congestion_control" = cc;

      "net.core.netdev_max_backlog" = netdevBacklog;
      "net.core.rmem_max" = rmemMax;
      "net.core.wmem_max" = wmemMax;
      "net.core.somaxconn" = somaxconn;

      "net.ipv4.tcp_rmem" = tcpRmem;
      "net.ipv4.tcp_wmem" = tcpWmem;
      "net.ipv4.tcp_max_syn_backlog" = synBacklog;
    };
in {
  # https://github.com/ENGINYRING/sysctl-Generator
  # https://github.com/jtsang4/nettune
  # https://github.com/wazar/sysctl-optimizer
  # https://github.com/ylx2016/Linux-NetSpeed
  # https://github.com/emadtoranji/NetworkOptimizer
  inherit defaults mkSysctl;
}
