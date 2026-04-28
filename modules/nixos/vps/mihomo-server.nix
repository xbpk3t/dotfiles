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
  port = 8443;
  handshakeServer = "www.bing.com";
  inventory = mylib.inventory."nixos-vps";
  nodeName = config.networking.hostName;
  singbox = mylib.inventory.singboxForHost inventory nodeName;
  hy2Enabled = singbox ? hy2;
  hy2Domain = singbox.hy2.domain;
  hy2Port = singbox.hy2.port or singbox.port or port;
  mail = userMeta.mail;

  serverConfig = builtins.toJSON {
    mode = "rule";
    log-level = "info";

    inbounds = [
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
            password = config.sops.placeholder.SINGBOX_HY2_PWD;
          }
        ];
        tls = {
          certificate_path = "/var/lib/acme/${hy2Domain}/fullchain.pem";
          key_path = "/var/lib/acme/${hy2Domain}/key.pem";
        };
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

      networking.firewall.allowedTCPPorts = [port];
      networking.firewall.allowedUDPPorts = lib.optionals hy2Enabled [hy2Port];
    }
    (mkIf hy2Enabled {
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
  ]);
}
