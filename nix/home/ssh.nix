_: {
  programs.ssh = {
    enable = true;

    # SSH client configuration
    extraConfig = ''
      # Disable strict host key checking (from ansible)
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null

      # Connection keep alive settings
      TCPKeepAlive yes
      ServerAliveInterval 15
      ServerAliveCountMax 6

      # Compression for slow connections
      Compression yes

      # Connection multiplexing
      ControlMaster auto
      ControlPath /tmp/%r@%h:%p
      ControlPersist yes

      # Additional useful settings
      # Automatically accept host keys for known hosts (less secure, but convenient)
      StrictHostKeyChecking accept-new

      # Hash known hosts for privacy
      HashKnownHosts yes

      # Enable verbose logging for debugging (uncomment if needed)
      # LogLevel VERBOSE

      # Forward SSH agent
      ForwardAgent yes

      # Enable X11 forwarding if needed
      ForwardX11 no

      # Disable GSSAPI authentication (speeds up connection)
      GSSAPIAuthentication no
      GSSAPIDelegateCredentials no

      # Preferred authentication methods
      PreferredAuthentications publickey,password

      # Ciphers and key exchange algorithms (security vs compatibility)
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
      HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa

      # Disable some deprecated or insecure features
      UseRoaming no
    '';
  };
}
