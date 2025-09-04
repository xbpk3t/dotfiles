{ ... }:

{
  # Network optimization configuration for macOS (darwin)
  # Based on equivalent Linux-Optimizer parameters adapted for macOS
  boot.kernel.sysctl = {
    # Enable TCP window scaling
    "net.inet.tcp.win_scale_factor" = 1;
    # Set maximum socket buffer size
    "kern.ipc.maxsockbuf" = 16777216;
    # Set TCP send buffer size
    "net.inet.tcp.sendspace" = 16777216;
    # Set TCP receive buffer size
    "net.inet.tcp.recvspace" = 16777216;
    # Optimize for low latency
    "net.inet.tcp.low_latency" = 1;
  };
}
