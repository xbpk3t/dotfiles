# NixOS networking configuration
_: {
  # Network optimization - Complete Linux server optimization parameters
  # Based on Linux-Optimizer project configurations for Ubuntu/Debian/CentOS/Fedora
  boot.kernel.sysctl = {
    # File system settings
    # Set the maximum number of open file descriptors
    "fs.file-max" = 67108864;

    # Network core settings
    # Specify default queuing discipline for network devices
    "net.core.default_qdisc" = "fq";
    # Configure maximum network device backlog
    "net.core.netdev_max_backlog" = 32768;
    # Set maximum socket receive buffer
    "net.core.optmem_max" = 262144;
    # Define maximum backlog of pending connections
    "net.core.somaxconn" = 65536;
    # Configure maximum TCP receive buffer size
    "net.core.rmem_max" = 33554432;
    # Set default TCP receive buffer size
    "net.core.rmem_default" = 1048576;
    # Configure maximum TCP send buffer size
    "net.core.wmem_max" = 33554432;
    # Set default TCP send buffer size
    "net.core.wmem_default" = 1048576;

    # TCP settings
    # Define socket receive buffer sizes
    "net.ipv4.tcp_rmem" = "16384 1048576 33554432";
    # Specify socket send buffer sizes
    "net.ipv4.tcp_wmem" = "16384 1048576 33554432";
    # Set TCP congestion control algorithm to BBR
    "net.ipv4.tcp_congestion_control" = "bbr";
    # Configure TCP FIN timeout period
    "net.ipv4.tcp_fin_timeout" = 25;
    # Set keepalive time (seconds)
    "net.ipv4.tcp_keepalive_time" = 1200;
    # Configure keepalive probes count and interval
    "net.ipv4.tcp_keepalive_probes" = 7;
    "net.ipv4.tcp_keepalive_intvl" = 30;
    # Define maximum orphaned TCP sockets
    "net.ipv4.tcp_max_orphans" = 819200;
    # Set maximum TCP SYN backlog
    "net.ipv4.tcp_max_syn_backlog" = 20480;
    # Configure maximum TCP Time Wait buckets
    "net.ipv4.tcp_max_tw_buckets" = 1440000;
    # Define TCP memory limits
    "net.ipv4.tcp_mem" = "65536 1048576 33554432";
    # Enable TCP MTU probing
    "net.ipv4.tcp_mtu_probing" = 1;
    # Define minimum amount of data in the send buffer before TCP starts sending
    "net.ipv4.tcp_notsent_lowat" = 32768;
    # Specify retries for TCP socket to establish connection
    "net.ipv4.tcp_retries2" = 8;
    # Enable TCP SACK and DSACK
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_dsack" = 1;
    # Disable TCP slow start after idle
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    # Enable TCP window scaling
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_adv_win_scale" = -2;
    # Enable TCP ECN
    "net.ipv4.tcp_ecn" = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;
    # Enable the use of TCP SYN cookies to help protect against SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;
    # Previously configured parameters
    "net.ipv4.tcp_low_latency" = 1;

    # UDP settings
    # Define UDP memory limits
    "net.ipv4.udp_mem" = "65536 1048576 33554432";

    # Virtual memory (VM) settings
    # Specify minimum free Kbytes at which VM pressure happens
    "vm.min_free_kbytes" = 65536;
    # Define how aggressively swap memory pages are used
    "vm.swappiness" = 10;
    # Set the tendency of the kernel to reclaim memory used for caching of directory and inode objects
    "vm.vfs_cache_pressure" = 250;
    # Set dirty page ratio for virtual memory
    "vm.dirty_ratio" = 20;
    # Strictly limits memory allocation to physical RAM + swap, preventing overcommit and reducing OOM risks
    "vm.overcommit_memory" = 2;
    # Sets overcommit to 100% of RAM when enabled, but ignored here since overcommit_memory = 2 disables it
    "vm.overcommit_ratio" = 100;

    # Network Configuration
    # Configure reverse path filtering
    "net.ipv4.conf.default.rp_filter" = 2;
    "net.ipv4.conf.all.rp_filter" = 2;
    # Disable source route acceptance
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    # Neighbor table settings
    "net.ipv4.neigh.default.gc_thresh1" = 512;
    "net.ipv4.neigh.default.gc_thresh2" = 2048;
    "net.ipv4.neigh.default.gc_thresh3" = 16384;
    "net.ipv4.neigh.default.gc_stale_time" = 60;
    # ARP settings
    "net.ipv4.conf.default.arp_announce" = 2;
    "net.ipv4.conf.lo.arp_announce" = 2;
    "net.ipv4.conf.all.arp_announce" = 2;

    # UNIX domain sockets
    # Set maximum queue length of UNIX domain sockets
    "net.unix.max_dgram_qlen" = 256;

    # Kernel settings
    # Kernel panic timeout
    "kernel.panic" = 1;
  };
}
