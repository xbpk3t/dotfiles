{
  config,
  lib,
  pkgs,
  mylib,
  userMeta,
  ...
}:
with lib; let
  cfg = config.services.mihomo-server;
  port = singbox.vlessPort or 8443;
  handshakeServer = "www.bing.com";
  inventory = mylib.inventory."nixos-vps";
  nodeName = config.networking.hostName;
  singbox = mylib.inventory.singboxForHost inventory nodeName;
  hy2Enabled = singbox ? hy2;
  hy2Domain = singbox.hy2.domain;
  # mihomo 不像 singbox 支持单端口协议复用，HY2 必须用独立端口
  hy2Port = singbox.hy2.port or 8500;
  vmessEnabled = singbox ? vmessWs;
  vmessDomain = attrByPath ["vmessWs" "domain"] null singbox;
  vmessPort = attrByPath ["vmessWs" "port"] null singbox;
  vmessPath = attrByPath ["vmessWs" "path"] null singbox;
  tuicEnabled = singbox ? tuic;
  tuicDomain = attrByPath ["tuic" "domain"] null singbox;
  tuicPort = attrByPath ["tuic" "port"] null singbox;
  tuicCongestionControl = attrByPath ["tuic" "congestionControl"] "bbr" singbox;
  anytlsEnabled = singbox ? anytls;
  anytlsDomain = attrByPath ["anytls" "domain"] null singbox;
  anytlsPort = attrByPath ["anytls" "port"] null singbox;
  needsStaticMihomoUser = hy2Enabled || vmessEnabled || tuicEnabled || anytlsEnabled;
  mail = userMeta.mail;

  serverConfig = builtins.toJSON {
    mode = "rule";
    log-level = "info";

    inbounds =
      [
        {
          type = "vless";
          tag = "vless-reality";
          listen = "::";
          listen_port = port;
          users = [
            {
              uuid = config.sops.placeholder.SINGBOX_UUID;
              flow = "xtls-rprx-vision";
            }
          ];
          reality-config = {
            dest = "${handshakeServer}:443";
            private-key = config.sops.placeholder.SINGBOX_PRI_KEY;
            short-id = [
              config.sops.placeholder.SINGBOX_ID
            ];
            server-names = [
              handshakeServer
            ];
          };
        }
        {
          type = "hysteria2";
          tag = "hy2-in";
          listen = "::";
          listen_port = hy2Port;
          users = [
            {
              password = config.sops.placeholder.SINGBOX_PWD;
            }
          ];
          tls = {
            certificate_path = "/var/lib/acme/${hy2Domain}/fullchain.pem";
            key_path = "/var/lib/acme/${hy2Domain}/key.pem";
          };
        }
      ]
      ++ lib.optionals vmessEnabled [
        {
          name = "vmess-ws-tls";
          type = "vmess";
          listen = "::";
          port = vmessPort;
          users = [
            {
              username = "1";
              uuid = config.sops.placeholder.SINGBOX_UUID;
              alterId = 0;
            }
          ];
          ws-path = vmessPath;
          certificate = "/var/lib/acme/${vmessDomain}/fullchain.pem";
          private-key = "/var/lib/acme/${vmessDomain}/key.pem";
        }
      ]
      ++ lib.optionals tuicEnabled [
        {
          name = "tuic-v5";
          type = "tuic";
          listen = "::";
          port = tuicPort;
          users = {
            "${config.sops.placeholder.SINGBOX_UUID}" = config.sops.placeholder.SINGBOX_PWD;
          };
          certificate = "/var/lib/acme/${tuicDomain}/fullchain.pem";
          private-key = "/var/lib/acme/${tuicDomain}/key.pem";
          congestion-controller = tuicCongestionControl;
          alpn = ["h3"];
        }
      ]
      ++ lib.optionals anytlsEnabled [
        {
          name = "anytls";
          type = "anytls";
          listen = "::";
          port = anytlsPort;
          users = {
            default = config.sops.placeholder.SINGBOX_PWD;
          };
          certificate = "/var/lib/acme/${anytlsDomain}/fullchain.pem";
          private-key = "/var/lib/acme/${anytlsDomain}/key.pem";
        }
      ];

    outbounds = [
      {
        type = "direct";
        tag = "direct";
      }
    ];

    route = {
      rules = [
        {
          outbound = "direct";
        }
      ];
    };
  };
in {
  options.services.mihomo-server = {
    enable = mkEnableOption "mihomo server (VLESS+Reality + Hysteria2 inbound)";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops.templates."mihomo-server.json".content = serverConfig;

      # https://mynixos.com/nixpkgs/options/services.mihomo
      services.mihomo = {
        enable = true;
        package = pkgs.mihomo;
        configFile = config.sops.templates."mihomo-server.json".path;
      };

      networking.firewall.allowedTCPPorts = [port] ++ lib.optionals vmessEnabled [vmessPort] ++ lib.optionals anytlsEnabled [anytlsPort];
      networking.firewall.allowedUDPPorts =
        lib.optionals hy2Enabled [hy2Port]
        ++ lib.optionals tuicEnabled [tuicPort];
    }
    (mkIf needsStaticMihomoUser {
      # 创建静态用户/组，确保在 ACME 签发证书前已存在
      # nixpkgs 的 services.mihomo 默认使用 DynamicUser，但动态用户
      # 在 ACME 运行时不存在，会导致证书权限设置失败 (217/USER)。
      # 解决方案：禁用 DynamicUser，改为静态用户，和 sing-box 模块一致。
      users.users.mihomo = {
        isSystemUser = true;
        group = "mihomo";
      };
      users.groups.mihomo = {};

      systemd.services.mihomo.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "mihomo";
        Group = "mihomo";
        # DynamicUser 使用 /var/lib/private/mihomo，静态用户使用 /var/lib/mihomo
        ExecStart = lib.mkForce (lib.concatStringsSep " " [
          (lib.getExe config.services.mihomo.package)
          "-d /var/lib/mihomo"
          "-f \${CREDENTIALS_DIRECTORY}/config.yaml"
          (lib.optionalString (config.services.mihomo.webui != null) "-ext-ui ${config.services.mihomo.webui}")
          (lib.optionalString (config.services.mihomo.extraOpts != null) config.services.mihomo.extraOpts)
        ]);
        # ProtectSystem=strict 会把 /var 挂载为空 tmpfs，ACME 证书在 /var/lib/acme
        # 下会不可见。通过 ReadOnlyPaths 为证书目录创建只读 bind mount。
        ReadOnlyPaths = ["/var/lib/acme"];
      };

      security.acme.acceptTerms = mkDefault true;
      security.acme.certs."${hy2Domain}" = {
        email = mail;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.ACME_CF_ENV.path;
        group = "mihomo";
        reloadServices = ["mihomo.service"];
      };
    })
    (mkIf vmessEnabled {
      security.acme.acceptTerms = mkDefault true;
      security.acme.certs."${vmessDomain}" = {
        email = mail;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.ACME_CF_ENV.path;
        group = "mihomo";
        reloadServices = ["mihomo.service"];
      };
    })
    (mkIf tuicEnabled {
      security.acme.acceptTerms = mkDefault true;
      security.acme.certs."${tuicDomain}" = {
        email = mail;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.ACME_CF_ENV.path;
        group = "mihomo";
        reloadServices = ["mihomo.service"];
      };
    })
    (mkIf anytlsEnabled {
      security.acme.acceptTerms = mkDefault true;
      security.acme.certs."${anytlsDomain}" = {
        email = mail;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.ACME_CF_ENV.path;
        group = "mihomo";
        reloadServices = ["mihomo.service"];
      };
    })
  ]);
}
