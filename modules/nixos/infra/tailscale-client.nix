{
  config,
  hostMeta,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.networking.tailscale;

  # Keep derper's STUN replies out of mihomo's policy-routing table.
  derperPolicyRoute = pkgs.writeShellScript "derper-policy-route" ''
    op=''${1:?add|del}
    uid="$(${pkgs.coreutils}/bin/id -u derper)"
    ${pkgs.iproute2}/bin/ip rule "$op" uidrange "$uid-$uid" lookup main priority 100 2>/dev/null || true
    ${pkgs.iproute2}/bin/ip -6 rule "$op" uidrange "$uid-$uid" lookup main priority 100 2>/dev/null || true
  '';
in
{
  # https://nixos.wiki/wiki/Tailscale

  # Taildrop
  # 我把一个文件通过此功能传到另一台linux机器上了，目标path在哪？需要自己取出文件
  ## sudo tailscale file get <目标路径>
  ## sudo tailscale file get ~/Downloads
  ## 取出到当前目录
  ## sudo tailscale file get .

  options.modules.networking.tailscale = {
    enable = mkEnableOption "Tailscale client (WireGuard-based mesh VPN) on this host";

    # 多角色：本机作为 exit node（转发出口）。
    # 开启后：useRoutingFeatures=server + --advertise-exit-node。
    # 批准由控制面（autoApprovers）+ 使用侧 grants 管理，模块不关心。
    exitNode = mkEnableOption "Advertise this host as a Tailscale exit node";

    derper = {
      enable = mkEnableOption "Tailscale DERP server on this host";

      # 域名只来自 hostMeta.derper.domain（不按 hostName 派生）；
      # TF DNS 由同一份 fleet metadata 生成，见 dns/README.md。
      domain = mkOption {
        type = types.str;
        default = hostMeta.derper.domain or "";
        description = "Public domain name for this DERP node (from hostMeta.derper.domain).";
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
        default = config.sops.secrets.ACME_CF_ENV.path;
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

      services.tailscale = {
        enable = true;
        package = pkgs.tailscale;
        openFirewall = true;
        authKeyFile = config.sops.secrets.TAILSCALE_AUTH_KEY.path;
        # 多角色：基础 client；exitNode 开启时提升为 "server"（开 ip_forward，exit node 必备）。
        # 纯 if（求值期）而非 mkIf（合并期）：mkIf false 会 fallback 到 NixOS 默认 "none"，
        # 丢掉 client 语义（rp_filter strict）——nixos-usb 等只开 enable 的 host 会回归。
        # 用 if 显式二选一：exitNode → server，否则 client。
        useRoutingFeatures = if cfg.exitNode then "server" else "client";
        # exitNode 时广播自己是出口。
        extraUpFlags = lib.mkIf cfg.exitNode [ "--advertise-exit-node" ];
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
          # domain 必须与 meta 一致：只检查 meta 存在还不够，
          # 否则 host 覆盖 option 时 ACME/derper 会用一个没有 DNS 记录的名字。
          assertion = cfg.derper.domain != "" && cfg.derper.domain == (hostMeta.derper.domain or "");
          message = "modules.networking.tailscale.derper.domain must be non-empty and match hostMeta.derper.domain.";
        }
      ];

      users.groups.derper = { };
      users.users.derper = {
        isSystemUser = true;
        group = "derper";
      };

      # Ensure tailscaled is running for verify-clients.
      services.tailscale = {
        enable = true;

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
      networking.firewall.allowedTCPPorts = [ cfg.derper.port ];
      networking.firewall.allowedUDPPorts = [ cfg.derper.stunPort ];

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
        reloadServices = [ "tailscale-derper.service" ];
        postRun = ''
          install -d -m 0750 -o root -g derper ${cfg.derper.certDir}
          install -m 0640 -o root -g derper /var/lib/acme/${cfg.derper.domain}/fullchain.pem ${cfg.derper.certDir}/${cfg.derper.domain}.crt
          install -m 0640 -o root -g derper /var/lib/acme/${cfg.derper.domain}/key.pem ${cfg.derper.certDir}/${cfg.derper.domain}.key
        '';
      };

      # Q: 本身 services.tailscale.derper 就会启动 systemd，为啥这里还要自己写一个systemd呢？
      # A: 这里覆盖 ExecStart，是为了让 derper 使用我们通过 DNS-01 拿到的证书（复制进 certDir）。原生模块使用它自己 默认证书路径，无法自动接入 DNS-01 的证书文件。
      systemd.services = {
        tailscale-derper.serviceConfig = {
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

        tailscale-derper = {
          requires = [ "acme-${cfg.derper.domain}.service" ];
          after = [
            "acme-${cfg.derper.domain}.service"
          ]
          ++ lib.optional config.services.mihomo.enable "derper-policy-route.service";
        };
      }
      // lib.optionalAttrs config.services.mihomo.enable {
        # mihomo 的 policy routing（table 2022）会接管 wildcard UDP socket 的源地址选择。
        # derper 的 STUN listener 绑定 [::]:stunPort，回包按 UID 选路由时会走 Meta，
        # 导致客户端收不到 STUN 响应（TCP DERP 不受影响）。给 derper UID 加高优先级
        # 规则，强制走 main 表（ens5），保留 mihomo 对其他流量的接管。
        derper-policy-route = {
          description = "Route derper packets outside mihomo TUN";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "mihomo.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${derperPolicyRoute} add";
            ExecStop = "${derperPolicyRoute} del";
          };
        };
      };

    })
  ];
}
