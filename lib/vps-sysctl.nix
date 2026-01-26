{lib}: let
  inherit (lib) max min mkDefault;

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

  # 将固定值包装为 mkDefault，方便下游覆盖
  mkDefaultAttrs = attrs: lib.mapAttrs (_: v: mkDefault v) attrs;

  mkSysctl = {
    bwMbps,
    rttMs,
    memGiB,
    mode ? "performance",
    cc ? "bbr",
    qdisc ? "fq",
    cpuCores ? null,
  }: let
    m = modeTable.${mode} or modeTable.balanced;

    cores =
      if cpuCores == null
      then 1
      else cpuCores;

    ramGiB = memGiB;
    ramBytes = memGiB * 1024 * 1024 * 1024;

    # 默认按 SSD/NVMe 处理（无额外入参时偏向更低 swap 与更积极的缓存策略）
    isSsd = true;

    # 使用 bwMbps 近似链路可用速率（VPS 通常无法可靠拿到真实 NIC 线速）
    nicMbps = bwMbps;
    has10g = nicMbps >= 10000;
    has1g = nicMbps >= 1000;

    # BDP 驱动 buffer 上限（结合 RTT 更贴近真实链路需求）
    bdp = bdpBytes bwMbps rttMs;
    scaledBdp = (bdp * m.factorNum) / m.factorDen;
    capBytes = (ramBytes * m.capPct) / 100;
    rounded = roundUp scaledBdp 4096;
    minBuf = 1024 * 1024;
    bufMax = max minBuf (min rounded capBytes);

    # 基础 buffer 下限来自脚本分档（1G/10G），再与 BDP 结果取较大值
    baseBuf =
      if has10g
      then 33554432
      else if has1g
      then 16777216
      else 4194304;

    rmemMax = max baseBuf bufMax;
    wmemMax = max baseBuf bufMax;

    rmemDefault = 2097152;
    wmemDefault = 2097152;

    tcpRmem =
      if has10g
      then "4096 262144 ${toString rmemMax}"
      else "4096 131072 ${toString rmemMax}";

    tcpWmem =
      if has10g
      then "4096 262144 ${toString wmemMax}"
      else "4096 131072 ${toString wmemMax}";

    # 内存保留：防止高压下频繁抖动与直接 OOM
    minFreeKb = clamp 65536 524288 (ramGiB * 4096);

    # 进程与文件句柄上限（按内存线性增长）
    pidMax = clamp 32768 4194304 (ramGiB * 16384);
    fileMax = clamp 65536 26214400 (ramGiB * 262144);

    # 连接并发相关（按 CPU 线性增长）
    somaxconn = clamp 4096 65535 (cores * 512);
    synBacklog = clamp 8192 262144 (cores * 1024);

    # NIC/吞吐相关队列
    netdevBacklog =
      if has10g
      then 250000
      else 30000;
    netdevBudget = clamp 300 1000 (cores * 20);
    netdevBudgetUsecs = clamp 2000 16000 (
      if nicMbps <= 1000
      then 4000
      else 8000
    );

    # 共享内存
    shmmax = (ramBytes * 90) / 100;
    shmall = shmmax / 4096;
    shmmni = max 4096 (ramGiB * 32);

    # TCP 初始拥塞窗口：基于 RTT 的轻度动态估计
    tcpInitCwnd = clamp 10 32 (rttMs / 20 + 10);

    # TCP 窗口广告缩放：高带宽场景更保守
    tcpAdvWinScale =
      if has10g
      then 1
      else 2;

    # 连接跟踪上限：按内存增长并钳制
    nfConntrackMax = clamp 262144 4194304 (ramGiB * 16384);

    # inotify 监控上限：按内存增长并钳制
    inotifyInstances = clamp 8192 65536 (ramGiB * 32);
    inotifyWatches = clamp 1048576 16777216 (ramGiB * 65536);

    # namespace 上限（容器场景参数，按内存增长并钳制）
    maxUserNamespaces = clamp 5000 30000 (ramGiB * 256);

    # hugepage 数量：偏保守，避免在小内存下过度预留
    nrHugepages = max 2 ((ramGiB * 156) / (cores + 1));
  in {
    # ################## KERNEL SETTINGS ############

    # PID/线程上限：按内存线性放大，避免高并发下过早触顶
    "kernel.pid_max" = pidMax;
    "kernel.threads-max" = pidMax;

    # CFS 调度片段：缩短时间片可降低延迟但会增加调度开销
    "kernel.sched_cfs_bandwidth_slice_us" = 3000;
    # RT 进程运行配额：留出 2% 给非 RT 任务，避免系统被 RT 压死
    "kernel.sched_rt_runtime_us" = 980000;
    # 子进程优先运行：关闭可避免 fork/exec 频繁抢占父进程
    "kernel.sched_child_runs_first" = 0;
    # 调度粒度与延迟：平衡吞吐与响应（通用基线）
    "kernel.sched_min_granularity_ns" = 10000;
    "kernel.sched_wakeup_granularity_ns" = 15000;
    "kernel.sched_latency_ns" = 60000;
    "kernel.sched_migration_cost_ns" = 50000;
    # 自动分组调度：服务器场景通常关闭以减少不可控的优先级扰动
    "kernel.sched_autogroup_enabled" = 0;

    # 共享内存上限：按内存 90% 计算，适合数据库/缓存类负载
    "kernel.shmmax" = shmmax;
    "kernel.shmall" = shmall;
    "kernel.shmmni" = shmmni;

    # Magic SysRq：保留紧急排障通道
    "kernel.sysrq" = 1;
    # panic 自动重启：缩短不可恢复故障时的停机窗口
    "kernel.panic" = 10;
    "kernel.panic_on_oops" = 1;

    # NUMA 自动平衡：大核机器可开启，小核/低并发默认关闭
    "kernel.numa_balancing" =
      if cores >= 32
      then 1
      else 0;

    # core 文件命名：保留进程名便于定位
    "kernel.core_pattern" = "core_%e";
    # printk：控制控制台日志级别，降低噪声避免刷屏
    "kernel.printk" = "3 4 1 3";

    # ASLR 强化：提升地址随机化强度
    "kernel.randomize_va_space" = 2;
    # 限制 dmesg：减少内核信息泄露面
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 1;
    # perf 权限：限制普通用户访问内核性能事件
    "kernel.perf_event_paranoid" = 2;
    "kernel.core_uses_pid" = 1;

    # tsc_reliable 不是所有内核都有此 sysctl，启用失败会被忽略
    "kernel.tsc_reliable" = 1;

    # 容器密钥/命名空间上限（避免被滥用导致内核资源耗尽）
    "kernel.keys.root_maxkeys" = clamp 10000 2000000 (ramGiB * 4096);
    "kernel.keys.root_maxbytes" = clamp 1000000 50000000 (ramGiB * 100000);
    "kernel.keys.maxkeys" = clamp 1000 4000 (ramGiB * 16);
    "kernel.keys.maxbytes" = clamp 1000000 4000000 (ramGiB * 16000);
    "user.max_user_namespaces" = maxUserNamespaces;
    "user.max_ipc_namespaces" = maxUserNamespaces;
    "user.max_pid_namespaces" = maxUserNamespaces;
    "user.max_net_namespaces" = maxUserNamespaces;
    "user.max_mnt_namespaces" = maxUserNamespaces;
    "user.max_uts_namespaces" = maxUserNamespaces;

    # ################## MEMORY MANAGEMENT ############

    # 默认按 SSD/NVMe 处理（减少 swap 参与，偏低延迟）
    "vm.swappiness" =
      if isSsd
      then 10
      else 20;

    # 脏页比例：内存越大越保守，避免大写入导致的卡顿
    "vm.dirty_ratio" =
      if ramGiB >= 16
      then 10
      else 15;
    "vm.dirty_background_ratio" =
      if ramGiB >= 16
      then 3
      else 5;
    "vm.dirty_expire_centisecs" = 1000;
    "vm.dirty_writeback_centisecs" = 100;

    # 最低保留内存：避免内核在紧张时频繁回收抖动
    "vm.min_free_kbytes" = minFreeKb;

    # vfs cache 压力：偏向保留 inode/dentry，提升热文件访问
    "vm.vfs_cache_pressure" = 50;

    # 关闭 zone reclaim：多数 VPS 上会带来额外延迟
    "vm.zone_reclaim_mode" = 0;

    # overcommit：脚本默认严格模式（0），如果 Nix 构建频繁失败可改为 1
    "vm.overcommit_memory" = 0;
    "vm.overcommit_ratio" = 50;

    "vm.max_map_count" = 1048576;
    "vm.page-cluster" = 0;
    "vm.oom_kill_allocating_task" = 1;
    "vm.panic_on_oom" = 1;

    # hugepage（部分内核不支持该 sysctl，可忽略失败）
    "vm.nr_hugepages" = nrHugepages;
    "vm.hugetlb_shm_group" = 0;
    "vm.transparent_hugepage.enabled" = "madvise";
    "vm.transparent_hugepage.defrag" = "never";

    # ################## NETWORK - CORE ############

    # recv/send buffer 上限：BDP 结果与分档下限取较大值
    "net.core.rmem_max" = rmemMax;
    "net.core.wmem_max" = wmemMax;
    "net.core.rmem_default" = rmemDefault;
    "net.core.wmem_default" = wmemDefault;

    # socket optmem 上限：高 PPS 时减少系统调用失败
    "net.core.optmem_max" = 4194304;

    # RX backlog：高 PPS 下缓冲突发包，避免软中断丢包
    "net.core.netdev_max_backlog" = netdevBacklog;

    # 软中断 budget：提高单轮处理量避免 backlog 堵塞
    "net.core.netdev_budget" = netdevBudget;
    "net.core.netdev_budget_usecs" = netdevBudgetUsecs;
    "net.core.dev_weight" = 64;

    # listen backlog 上限：提升高并发建连能力
    "net.core.somaxconn" = somaxconn;

    # busy poll/read：降低延迟但会占用 CPU
    "net.core.busy_poll" = 50;
    "net.core.busy_read" = 50;

    # 队列算法：默认 fq，更稳妥；如需 cake 可在 inventory 覆盖
    "net.core.default_qdisc" = qdisc;

    # ################## NETWORK - TCP ############

    # TCP buffer：与 rmem/wmem 保持一致，避免 autotune 混乱
    "net.ipv4.tcp_rmem" = tcpRmem;
    "net.ipv4.tcp_wmem" = tcpWmem;

    # TCP/UDP 内存水位
    "net.ipv4.tcp_mem" = "786432 1048576 26777216";
    "net.ipv4.udp_mem" = "4194304 8388608 16777216";
    "net.ipv4.udp_rmem_min" = 16384;
    "net.ipv4.udp_wmem_min" = 16384;

    # 拥塞控制与窗口
    "net.ipv4.tcp_congestion_control" = cc;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_dsack" = 1;
    "net.ipv4.tcp_adv_win_scale" = tcpAdvWinScale;

    # 连接建立与回收
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_max_syn_backlog" = synBacklog;
    "net.ipv4.tcp_max_tw_buckets" = 2000000;
    "net.ipv4.tcp_fin_timeout" = 10;
    "net.ipv4.tcp_tw_reuse" = 1;
    # tw_recycle 已废弃，保持关闭避免 NAT/移动网络异常
    "net.ipv4.tcp_tw_recycle" = 0;
    "net.ipv4.tcp_synack_retries" = 2;
    "net.ipv4.tcp_syn_retries" = 2;
    "net.ipv4.tcp_syncookies" = 1;

    # 连接异常处理
    "net.ipv4.tcp_abort_on_overflow" = 0;
    "net.ipv4.tcp_orphan_retries" = 1;
    "net.ipv4.tcp_max_orphans" = clamp 32768 262144 (ramGiB * 16384);

    # 延迟与吞吐折中
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_moderate_rcvbuf" = 1;
    "net.ipv4.tcp_notsent_lowat" = 16384;
    "net.ipv4.tcp_low_latency" = 1;
    "net.ipv4.tcp_no_metrics_save" = 1;
    "net.ipv4.tcp_early_retrans" = 3;
    "net.ipv4.tcp_retries2" = 8;
    "net.ipv4.tcp_frto" = 2;
    "net.ipv4.tcp_fack" = 1;
    "net.ipv4.tcp_ecn" = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;
    "net.ipv4.tcp_rfc1337" = 0;
    "net.ipv4.tcp_stdurg" = 0;
    "net.ipv4.tcp_autocorking" = 0;
    "net.ipv4.tcp_delack_min" = 10;
    "net.ipv4.tcp_init_cwnd" = tcpInitCwnd;

    # Keepalive：缩短空闲探测，加快失联识别
    "net.ipv4.tcp_keepalive_time" = 600;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 6;

    # ################## NETWORK - IPV4 ############

    # 本地端口范围：扩大可用 ephemeral ports
    "net.ipv4.ip_local_port_range" = "1024 65535";

    # PMTU 探测：0 表示启用（推荐）
    "net.ipv4.ip_no_pmtu_disc" = 0;

    # 路由转发：默认关闭，需要做路由/网关时再启用
    "net.ipv4.ip_forward" = 0;
    "net.ipv4.conf.all.forwarding" = 0;
    "net.ipv4.conf.default.forwarding" = 0;

    # 邻居表回收策略
    "net.ipv4.neigh.default.gc_stale_time" = 120;
    "net.ipv4.neigh.default.gc_thresh3" = 8192;
    "net.ipv4.neigh.default.gc_thresh2" = 4096;
    "net.ipv4.neigh.default.gc_thresh1" = 1024;
    "net.ipv4.neigh.default.unres_qlen" = 10000;

    # 路由缓存回收
    "net.ipv4.route.gc_timeout" = 100;

    # ICMP 安全
    "net.ipv4.icmp_echo_ignore_all" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

    # 反向路径过滤（防 IP 欺骗；多宿主需谨慎）
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # ARP 宣告/忽略（减少 ARP 混乱与欺骗）
    "net.ipv4.conf.all.arp_filter" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;
    "net.ipv4.conf.default.arp_announce" = 2;
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.default.arp_ignore" = 1;

    # Redirect 与源路由：关闭以减少攻击面
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;

    # 记录火星包：默认关闭，必要时自行打开
    "net.ipv4.conf.all.log_martians" = 0;

    # route_localnet：默认关闭，避免 127.0.0.0/8 被错误路由
    "net.ipv4.conf.all.route_localnet" = 0;

    # ################## NETWORK - IPV6 ############

    # IPv6 默认开启；需要完全禁用时统一改为 1
    "net.ipv6.conf.all.disable_ipv6" = 0;
    "net.ipv6.conf.default.disable_ipv6" = 0;
    "net.ipv6.conf.lo.disable_ipv6" = 0;

    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;

    "net.ipv6.conf.all.forwarding" = 0;
    "net.ipv6.conf.default.forwarding" = 0;
    "net.ipv6.conf.lo.forwarding" = 0;

    "net.ipv6.neigh.default.gc_thresh1" = 1024;
    "net.ipv6.neigh.default.gc_thresh2" = 4096;
    "net.ipv6.neigh.default.gc_thresh3" = 8192;

    # ################## NETWORK - BRIDGE ############

    # 桥接过滤开关：默认关闭，容器/网关场景需评估后再开启
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-arptables" = 0;

    # ################## NETFILTER / CONNTRACK ############

    # 连接跟踪表上限：按内存线性增长并钳制
    "net.netfilter.nf_conntrack_max" = nfConntrackMax;
    "net.nf_conntrack_max" = nfConntrackMax;

    # 连接跟踪超时（提升高并发场景下资源回收速度）
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 432000;
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait" = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait" = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_close_wait" = 30;

    # ################## SUNRPC / NFS ############

    "sunrpc.tcp_slot_table_entries" = clamp 64 256 (ramGiB / 4);
    "sunrpc.udp_slot_table_entries" = clamp 64 256 (ramGiB / 4);
    "fs.nfsd.max_connections" = clamp 256 65536 (ramGiB * 64);

    # ################## FILESYSTEM LIMITS ############

    # 文件句柄：按内存增长，避免高并发下触顶
    "fs.file-max" = fileMax;
    "fs.nr_open" = max 26214400 fileMax;

    "fs.aio-max-nr" = 1048576;
    "fs.inotify.max_user_instances" = inotifyInstances;
    "fs.inotify.max_user_watches" = inotifyWatches;
    "fs.suid_dumpable" = 0;

    # ################## UNIX DOMAIN SOCKETS ############

    # 本地 dgram queue 长度：承载突发 IPC
    "net.unix.max_dgram_qlen" = 256;
  };

  # 默认配置（mkDefault）：用于无硬件输入时的保守基线
  mkDefaultSysctl = mkDefaultAttrs (mkSysctl {
    bwMbps = 1000;
    rttMs = 50;
    memGiB = 1;
    cpuCores = 1;
    mode = "balanced";
    cc = "bbr";
    qdisc = "fq";
  });
in {
  inherit mkSysctl mkDefaultSysctl;
}
