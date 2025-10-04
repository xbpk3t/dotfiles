# Network performance optimization
# These are safe, widely-used network optimization parameters
# that improve performance for both desktop and server environments
_: {
  # Network and system performance optimization
  # Based on proven configurations from Linux-Optimizer project
  boot.kernel.sysctl = {
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
  };
}
