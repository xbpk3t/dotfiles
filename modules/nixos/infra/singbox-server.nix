{
  config,
  hostMeta,
  lib,
  userMeta,
  ...
}:
with lib;
let
  cfg = config.modules.infra.singbox-server;
  # 端口/path/协议参数由 lib/fleet 的 normalizeSingbox 归一化后保证存在；
  # 这里直接读取，缺字段会在 eval 阶段报错，而不是静默回退到第二份默认值。
  port = singbox.vlessPort;
  # 伪装握手目标域名（随便换一个稳定的大站都行）
  handshakeServer = "www.bing.com";
  # 本机发布的 singbox 能力；由 fleet registry 同步给所有 client。
  # 不再按 hostname 去 inventory 里反查，host 改名不会静默失效。
  singbox = hostMeta.singbox or { };
  hy2Enabled = singbox ? hy2;
  hy2Domain = singbox.hy2.domain;
  hy2Port = singbox.hy2.port;
  vmessEnabled = singbox ? vmessWs;
  vmessDomain = singbox.vmessWs.domain;
  vmessPort = singbox.vmessWs.port;
  vmessPath = singbox.vmessWs.path;
  tuicEnabled = singbox ? tuic;
  tuicDomain = singbox.tuic.domain;
  tuicPort = singbox.tuic.port;
  tuicCongestionControl = singbox.tuic.congestionControl;
  anytlsEnabled = singbox ? anytls;
  anytlsDomain = singbox.anytls.domain;
  anytlsPort = singbox.anytls.port;
  anytlsAlpn = singbox.anytls.alpn;
  # 本模块需要的 TLS 证书域名；acme ensure units 和 security.acme.certs
  # 都从这一份列表派生，新增协议只需改一处。
  acmeDomains =
    optional hy2Enabled hy2Domain
    ++ optional vmessEnabled vmessDomain
    ++ optional tuicEnabled tuicDomain
    ++ optional anytlsEnabled anytlsDomain;
  # 每个域名对应的 acme ensure unit：它负责在 lego 真正签发前先落地
  # self-signed 证书文件。sing-box 冷启动必须排在这些 unit 之后。
  acmeServices = map (domain: "acme-${domain}.service") acmeDomains;
  inherit (userMeta) mail;
in
{
  options.modules.infra.singbox-server = {
    enable = mkEnableOption "sing-box server (Reality)";
  };

  # vless+reality

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = hostMeta ? singbox;
        message = "modules.infra.singbox-server requires hostMeta.singbox in the fleet registry.";
      }
    ];

    # 通过以下命令生成 singbox node 的相应metadata，直接放到sops里，并且分发到所有nodes里。没必要分开配置，方便client端组装。
    # sing-box generate uuid
    # sing-box generate reality-keypair
    # sing-box generate rand 8 --hex

    # !!!
    # 1. 注意里面的 `sops` + `_secret` 写法。先后尝试了几种写法（sops直接从 uuid = config.sops. 读取secret，但是这里不接受 filepath，只要明文secret，所以在evaluate时就失败。之后换成了 sops template写法和从 /run/secrets/xxx里直接 builtins.readFile（这个写法需要本地先有相应文件） ）

    # 冷启动时 acme-<domain>.service 先创建证书文件（或 self-signed
    # fallback），再让 sing-box 启动；只等 ensure，不等真实 lego 签发。
    systemd.services.sing-box = {
      after = acmeServices;
      wants = acmeServices;
    };

    services.sing-box = {
      enable = true;
      settings = {
        log = {
          level = "info";
        };

        inbounds = [
          {
            type = "vless";
            tag = "vless-reality";
            listen = "::";
            listen_port = port;

            users = [
              {
                uuid = {
                  _secret = config.sops.secrets.PROXY_UUID.path;
                };
                flow = "xtls-rprx-vision";
              }
            ];

            tls = {
              enabled = true;
              server_name = handshakeServer;

              reality = {
                enabled = true;

                handshake = {
                  server = handshakeServer;
                  server_port = 443;
                };

                # 从 sops 文件读入
                private_key = {
                  _secret = config.sops.secrets.PROXY_PRI_KEY.path;
                };

                # short_id 允许多个，这里只用一个
                short_id = [
                  { _secret = config.sops.secrets.PROXY_ID.path; }
                ];
              };
            };
          }
        ]
        ++ lib.optionals vmessEnabled [
          {
            type = "vmess";
            tag = "vmess-ws-tls";
            listen = "::";
            listen_port = vmessPort;

            users = [
              {
                name = "default";
                uuid = {
                  _secret = config.sops.secrets.PROXY_UUID.path;
                };
                alterId = 0;
              }
            ];

            tls = {
              enabled = true;
              server_name = vmessDomain;
              certificate_path = "/var/lib/acme/${vmessDomain}/fullchain.pem";
              key_path = "/var/lib/acme/${vmessDomain}/key.pem";
            };

            transport = {
              type = "ws";
              path = vmessPath;
            };
          }
        ]
        ++ lib.optionals hy2Enabled [
          {
            type = "hysteria2";
            tag = "hy2";
            listen = "::";
            listen_port = hy2Port;

            users = [
              {
                password = {
                  _secret = config.sops.secrets.PROXY_PWD.path;
                };
              }
            ];

            tls = {
              enabled = true;
              server_name = hy2Domain;
              alpn = [ "h3" ];
              certificate_path = "/var/lib/acme/${hy2Domain}/fullchain.pem";
              key_path = "/var/lib/acme/${hy2Domain}/key.pem";
            };
          }
        ]
        ++ lib.optionals tuicEnabled [
          {
            type = "tuic";
            tag = "tuic";
            listen = "::";
            listen_port = tuicPort;

            users = [
              {
                name = "default";
                uuid = {
                  _secret = config.sops.secrets.PROXY_UUID.path;
                };
                password = {
                  _secret = config.sops.secrets.PROXY_PWD.path;
                };
              }
            ];

            congestion_control = tuicCongestionControl;
            zero_rtt_handshake = false;
            heartbeat = "10s";
            tls = {
              enabled = true;
              server_name = tuicDomain;
              alpn = [ "h3" ];
              certificate_path = "/var/lib/acme/${tuicDomain}/fullchain.pem";
              key_path = "/var/lib/acme/${tuicDomain}/key.pem";
            };
          }
        ]
        ++ lib.optionals anytlsEnabled [
          {
            type = "anytls";
            tag = "anytls";
            listen = "::";
            listen_port = anytlsPort;

            users = [
              {
                name = "default";
                password = {
                  _secret = config.sops.secrets.PROXY_PWD.path;
                };
              }
            ];

            tls = {
              enabled = true;
              server_name = anytlsDomain;
              alpn = anytlsAlpn;
              certificate_path = "/var/lib/acme/${anytlsDomain}/fullchain.pem";
              key_path = "/var/lib/acme/${anytlsDomain}/key.pem";
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
            { outbound = "direct"; }
          ];
        };
      };
    };

    # 放行端口
    networking.firewall.allowedTCPPorts = [
      port
    ]
    ++ lib.optionals vmessEnabled [ vmessPort ]
    ++ lib.optionals anytlsEnabled [ anytlsPort ];
    networking.firewall.allowedUDPPorts =
      lib.optionals hy2Enabled [ hy2Port ] ++ lib.optionals tuicEnabled [ tuicPort ];

    # lego 5.5.1 的 DNS-01 校验默认连递归解析器一起查；systemd-resolved
    # 会缓存 Cloudflare 在创建 TXT 之前查询 _acme-challenge 得到的 NXDOMAIN
    # （lucc.dev 的 SOA minimum 是 1800s），导致 TXT 已生效但校验仍失败。
    # 只保留权威 NS 校验：ACME CA 最终看到的也是权威数据。
    # 只作用于本模块的证书，不污染同机其他证书。
    security.acme = {
      acceptTerms = mkDefault true;
      certs = genAttrs acmeDomains (_domain: {
        email = mail;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.ACME_CF_ENV.path;
        group = "sing-box";
        # 证书更新后自动 reload，避免继续使用旧证书。
        reloadServices = [ "sing-box.service" ];
        extraLegoFlags = [ "--dns.propagation.disable-rns" ];
      });
    };
  };
}
