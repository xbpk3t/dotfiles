{
  pkgs,
  myvars,
  ...
}: {
  # 只在桌面下添加 nixos container. 否则在 VPS 里（即使不启用）也会占用磁盘
  # https://mynixos.com/nixpkgs/option/containers
  containers = {
    nixos-minimal = {
      # 配置为不要自启，需要 sudo nixos-container start nixos-minimal 手动启动
      autoStart = false;
      ephemeral = false;
      privateNetwork = true;
      hostAddress = "10.254.0.1";
      localAddress = "10.254.0.2";
      specialArgs = {
        inherit myvars;
      };
      config = {
        imports = [
          (pkgs.path + "/nixos/modules/profiles/minimal.nix")
        ];

        networking.hostName = "nixos-minimal";
        networking.firewall.allowedTCPPorts = [22];

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "prohibit-password";
            PasswordAuthentication = false;
          };
        };

        users.users.root.openssh.authorizedKeys.keys =
          myvars.SSHPubKeys or [];

        system.stateVersion = "24.11";
      };
    };

    # https://nixos.wiki/wiki/NixOS_Containers
    #    nextcloud = {
    #      autoStart = false;
    #      privateNetwork = true;
    #      hostAddress = "192.168.100.10";
    #      localAddress = "192.168.100.11";
    #      hostAddress6 = "fc00::1";
    #      localAddress6 = "fc00::2";
    #      config = {
    #        # service-specific configuration
    #      };
    #    };
  };
}
