# NixOS boot configuration
{ ... }:

{
  # Basic boot configuration
  boot = {
    # Use systemd-boot for UEFI systems, GRUB for legacy
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # Fallback to GRUB if needed
      # grub = {
      #   enable = true;
      #   device = "/dev/sda"; # Set per-host
      # };
    };

    # Kernel modules for containers and networking (from k8s-optimize.sh)
    kernelModules = [ "br_netfilter" ];

    # Kernel parameters for performance
    kernel.sysctl = {
      # Network performance (from ansible centos_servers.yml)
      "net.core.rmem_default" = 262144;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_default" = 262144;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 65536 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";

      # Memory management
      "vm.swappiness" = 10;

      # Container/K8s networking (from k8s-optimize.sh)
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;
    };
  };

  # Disable swap for K8s compatibility (from k8s-optimize.sh)
  swapDevices = [ ];
}
