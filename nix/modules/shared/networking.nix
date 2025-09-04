{ ... }:

{
  # Cross-platform network optimization configuration
  # These are the basic network optimization parameters that work across platforms
  boot.kernel.sysctl = {
    # Enable TCP window scaling
    "net.ipv4.tcp_window_scaling" = 1;
    # Set maximum receive socket buffer
    "net.core.rmem_max" = 16777216;
    # Set maximum send socket buffer
    "net.core.wmem_max" = 16777216;
    # Define TCP receive buffer sizes (min, default, max)
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    # Define TCP send buffer sizes (min, default, max)
    "net.ipv4.tcp_wmem" = "4096 16384 16777216";
    # Optimize for low latency
    "net.ipv4.tcp_low_latency" = 1;
    # Do not enter slow start after idle
    "net.ipv4.tcp_slow_start_after_idle" = 0;
  };
}
