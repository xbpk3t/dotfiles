# NixOS SSH service configuration
# Based on Linux-Optimizer project configurations for Ubuntu/Debian/CentOS/Fedora
_: {
  # SSH optimization
  services.openssh = {
    enable = true;
    settings = {
      # Additional SSH optimizations from Linux-Optimizer
      # Disable DNS lookup to speed up connections
      UseDNS = false;
      # Enable compression
      Compression = true;
      # Set strong ciphers
      Ciphers = [
        "aes256-ctr"
        "chacha20-poly1305@openssh.com"
      ];
      # Enable TCP keep-alive messages
      TCPKeepAlive = true;
      # Configure client keep-alive messages (3000 seconds)
      ClientAliveInterval = 3000;
      # Set maximum client alive count (100)
      ClientAliveCountMax = 100;
      # Allow TCP forwarding
      AllowTcpForwarding = true;
      # Enable gateway ports
      GatewayPorts = "yes";
      # Enable tunneling
      PermitTunnel = true;
      # Enable X11 graphical interface forwarding
      X11Forwarding = true;

      # 安全相关配置
      # 禁用密码认证，只允许公钥认证
      PasswordAuthentication = false;
      # 禁止root用户直接登录
      PermitRootLogin = "prohibit-password";
      # 启用公钥认证
      PubkeyAuthentication = true;
    };
  };
}
