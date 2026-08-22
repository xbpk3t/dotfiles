_: {

  # Network services configuration
  # [services.openssh - MyNixOS](https://mynixos.com/nix-darwin/options/services.openssh)
  services = {
    # Note: NTP service is not configurable through nix-darwin
    # macOS handles time synchronization automatically

    # Enable SSH daemon
    openssh = {
      enable = true;
      # nix-darwin 无结构化 settings，SSH 收紧走裸文本（对应你需 NixOS 的
      # kernel/openssh.nix 基线）。只保留 nix 托管的密钥认证，禁密码/键盘交互/root。
      extraConfig = ''
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        PermitRootLogin no
        LogLevel VERBOSE
      '';
    };
    # Note: SSH configuration on macOS is more limited than on NixOS
    # Most SSH settings are managed through /etc/ssh/sshd_config
  };
}
