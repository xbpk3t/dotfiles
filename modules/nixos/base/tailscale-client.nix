{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.tailscale;
in {
  options.modules.networking.tailscale = {
    enable = mkEnableOption "Tailscale client (WireGuard-based mesh VPN) on this host";

    derper = {
      enable = mkEnableOption "Tailscale DERP server on this host";

      # 需要
      domain = mkOption {
        type = types.str;
        # 静态方案：默认由主机名派生域名，但最终应在 inventory/host 层显式指定
        default = "derp-${config.networking.hostName}.lucc.dev";
        description = "Public domain name for this DERP node.";
      };

      port = mkOption {
        type = types.port;
        default = 10043;
        description = "DERP TCP port (non-443) to listen on.";
      };

      stunPort = mkOption {
        type = types.port;
        default = 10078;
        description = "STUN UDP port to listen on.";
      };

      acmeEmail = mkOption {
        type = types.str;
        default = "";
        description = "Email for ACME account registration.";
      };

      dnsProvider = mkOption {
        type = types.str;
        default = "cloudflare";
        description = "ACME DNS-01 provider (e.g. cloudflare).";
      };

      acmeEnvironmentFile = mkOption {
        type = types.str;
        default = config.sops.secrets.acme_cloudflare_env.path;
        description = "Path to ACME DNS-01 environment file.";
      };

      certDir = mkOption {
        type = types.str;
        default = "/var/lib/derper/certs";
        description = "Directory containing DERP TLS cert and key (hostname.crt/key).";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.tailscale
      ];

      # https://mynixos.com/nixpkgs/options/services.tailscale
      services.tailscale = {
        enable = true;
        package = pkgs.tailscale;
        # Keep it as a regular client; enables subnet/exit-node routing only when needed.
        useRoutingFeatures = "client";
        openFirewall = true;
      };

      environment.shellAliases = {
        tss = "tailscale";
      };
    })

    (mkIf cfg.derper.enable {
      assertions = [
        {
          assertion = cfg.derper.acmeEmail != "";
          message = "modules.networking.tailscale.derper.acmeEmail must be set when derper is enabled.";
        }
        {
          assertion = cfg.derper.domain != "";
          message = "modules.networking.tailscale.derper.domain must be set when derper is enabled.";
        }
      ];

      users.groups.derper = {};
      users.users.derper = {
        isSystemUser = true;
        group = "derper";
      };

      # Ensure tailscaled is running for verify-clients.
      services.tailscale = {
        enable = true;

        # https://mynixos.com/nixpkgs/options/services.tailscale.derper
        derper = {
          enable = true;
          domain = cfg.derper.domain;
          port = cfg.derper.port;
          stunPort = cfg.derper.stunPort;
          # 防白嫖：使用 tailscale 客户端鉴权（等价 DERP_VERIFY_CLIENTS=true）
          verifyClients = true;
          configureNginx = false;
          openFirewall = false;
        };
      };

      # 端口映射：DERP TCP / STUN UDP
      networking.firewall.allowedTCPPorts = [cfg.derper.port];
      networking.firewall.allowedUDPPorts = [cfg.derper.stunPort];

      security.acme.acceptTerms = mkDefault true;

      # Q: 我的核心需求就是，所有nixos-vps机器，既是 client，又是 derp。所以这里真的需要域名吗？为啥每个IP都要配置各自的域名？还是说直接 IP访问也行？
      # A:
      # 上游 derper 走的是标准 TLS 校验，所以必须有域名。目前生态里“只用 IP 的 TLS”并不顺滑，且 upstream derper 预期用hostname 证书；不使用域名就等于走弱校验/绕过校验的路线，这与你的诉求相反。
      security.acme.certs."${cfg.derper.domain}" = {
        email = cfg.derper.acmeEmail;
        dnsProvider = cfg.derper.dnsProvider;
        # 注意这里
        # https://mynixos.com/nixpkgs/option/security.acme.certs.%3Cname%3E.environmentFile
        environmentFile = cfg.derper.acmeEnvironmentFile;
        reloadServices = ["tailscale-derper.service"];
        postRun = ''
          install -d -m 0750 -o root -g derper ${cfg.derper.certDir}
          install -m 0640 -o root -g derper /var/lib/acme/${cfg.derper.domain}/fullchain.pem ${cfg.derper.certDir}/${cfg.derper.domain}.crt
          install -m 0640 -o root -g derper /var/lib/acme/${cfg.derper.domain}/key.pem ${cfg.derper.certDir}/${cfg.derper.domain}.key
        '';
      };

      # Q: 本身 services.tailscale.derper 就会启动 systemd，为啥这里还要自己写一个systemd呢？
      # A: 这里覆盖 ExecStart，是为了让 derper 使用我们通过 DNS-01 拿到的证书（复制进 certDir）。原生模块使用它自己 默认证书路径，无法自动接入 DNS-01 的证书文件。
      systemd.services.tailscale-derper.serviceConfig = {
        DynamicUser = mkForce false;
        User = "derper";
        Group = "derper";
        # 让 ExecStartPre 以 root 执行。否则以 derper 用户执行，会报没权限，导致报错
        PermissionsStartOnly = true;

        # Ensure certs exist in certDir before derper starts (ACME outputs live in /var/lib/acme).
        ExecStartPre = [
          "${pkgs.coreutils}/bin/install -d -m 0750 -o root -g derper ${cfg.derper.certDir}"
          "${pkgs.coreutils}/bin/install -m 0640 -o root -g derper /var/lib/acme/${cfg.derper.domain}/fullchain.pem ${cfg.derper.certDir}/${cfg.derper.domain}.crt"
          "${pkgs.coreutils}/bin/install -m 0640 -o root -g derper /var/lib/acme/${cfg.derper.domain}/key.pem ${cfg.derper.certDir}/${cfg.derper.domain}.key"
        ];

        # -c 用于持久化服务密钥
        ExecStart = mkForce ''
          ${lib.getExe' config.services.tailscale.derper.package "derper"} \
            -a :${toString cfg.derper.port} \
            -c /var/lib/derper/derper.key \
            -stun-port ${toString cfg.derper.stunPort} \
            -hostname=${cfg.derper.domain} \
            -certmode=manual \
            -certdir=${cfg.derper.certDir} \
            -verify-clients \
            -http-port=-1
        '';
      };

      systemd.services.tailscale-derper = {
        requires = ["acme-${cfg.derper.domain}.service"];
        after = ["acme-${cfg.derper.domain}.service"];
      };
    })
  ];
}
