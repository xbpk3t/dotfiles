{
  config,
  lib,
  pkgs,
  myvars,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  client = import ../../../lib/singbox/client-config.nix {inherit config myvars lib;};
  clientConfigPath = client.clientConfigPath;
in {
  # https://mynixos.com/nixpkgs/options/services.sing-box

  # 只有desktop才需要引入singbox（因为所有VPS默认本身都不需要挂singbox），所以放在这里
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box proxy service";
  };

  config = mkIf cfg.enable {
    # Install sing-box package
    environment.systemPackages = [
      pkgs.sing-box
    ];

    # 运行时渲染配置，避免密钥进入 /nix/store
    sops.templates."singbox-client.json".content = client.templatesContent;

    # Create systemd system service for sing-box (requires root for TUN interface)
    systemd.services.singbox = {
      description = "Sing-box Proxy Service";
      wantedBy = ["multi-user.target"];
      # 确保配置文件存在后再启动
      # FIXME 经常会遇到前面的 update-config 失败，导致singbox无法启动，这种问题怎么解决？
      # after = ["network-online.target" "singbox-update-config.service"];
      # requires = ["singbox-update-config.service"];

      serviceConfig = {
        Type = "simple";
        # 统一使用 cfg_path 指定的配置文件
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${clientConfigPath}";
        Restart = "always";
        RestartSec = "5s";

        # Security: Required capabilities for TUN interface
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_DAC_OVERRIDE";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_DAC_OVERRIDE";

        # Run as root (required for TUN interface creation)
        User = "root";

        # Minimal security hardening
        # Note: Cannot use ProtectHome or ProtectSystem=strict as they would
        # prevent reading config from /etc or accessing /home
        NoNewPrivileges = false; # Must be false for capabilities
        # 需访问宿主 /var/lib/sing-box/config.json，因此禁用 PrivateTmp
        PrivateTmp = false;
      };
    };

    # Ensure state dir exists with correct ownership before service start
    systemd.tmpfiles.rules = [
      "d /var/lib/sing-box 0700 root root -"
    ];
  };
}
