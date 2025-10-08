{lib, ...}: {
  # Or disable the firewall altogether.
  networking.firewall.enable = lib.mkDefault false;
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;

      # root user is used for remote deployment, so we need to allow it
      # 禁止root用户直接登录
      PermitRootLogin = "prohibit-password";
      # FIXME 暂时开启密码登录
      # 禁用密码认证，只允许公钥认证
      # PasswordAuthentication = false; # disable password login
      PasswordAuthentication = true; # disable password login

      # Additional SSH optimizations from Linux-Optimizer
      # Disable DNS lookup to speed up connections
      # 注意应该使用 UseDns 而非 UseDNS，否则会有配置冲突问题
      UseDns = false;
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
      # 启用公钥认证
      PubkeyAuthentication = true;
    };

    openFirewall = true;
  };

  # Add terminfo database of all known terminals to the system profile.
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/config/terminfo.nix
  environment.enableAllTerminfo = true;
}
