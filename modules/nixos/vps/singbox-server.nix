{
  config,
  lib,
  mylib,
  myvars,
  ...
}:
with lib; let
  cfg = config.services.singbox-server;
  port = 8443;
  # 伪装握手目标域名（随便换一个稳定的大站都行）
  handshakeServer = "www.bing.com";
  inventory = import (mylib.relativeToRoot "inventory/nixos-vps.nix");
  nodeName = config.networking.hostName;
  singbox = mylib.inventory.singboxForHost inventory nodeName;
  hy2Enabled = singbox ? hy2;
  hy2Domain = singbox.hy2.domain;
  hy2Port = singbox.hy2.port or singbox.port or port;
in {
  options.services.singbox-server = {
    enable = mkEnableOption "sing-box server (Reality)";
  };

  # vless+reality

  config = mkIf cfg.enable (mkMerge [
    {
      # 通过以下命令生成 singbox node 的相应metadata，直接放到sops里，并且分发到所有nodes里。没必要分开配置，方便client端组装。
      # sing-box generate uuid
      # sing-box generate reality-keypair
      # sing-box generate rand 8 --hex

      # !!!
      # 1. 注意里面的 `sops` + `_secret` 写法。先后尝试了几种写法（sops直接从 uuid = config.sops. 读取secret，但是这里不接受 filepath，只要明文secret，所以在evaluate时就失败。之后换成了 sops template写法和从 /run/secrets/xxx里直接 builtins.readFile（这个写法需要本地先有相应文件） ）

      # https://mynixos.com/nixpkgs/options/services.sing-box
      services.sing-box = {
        enable = true;
        settings = {
          log = {
            level = "info";
          };

          inbounds =
            [
              {
                type = "vless";
                tag = "vless-reality";
                listen = "::";
                listen_port = port;

                users = [
                  {
                    uuid = {_secret = config.sops.secrets.singbox_UUID.path;};
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
                    private_key = {_secret = config.sops.secrets.singbox_pri_key.path;};

                    # short_id 允许多个，这里只用一个
                    short_id = [
                      {_secret = config.sops.secrets.singbox_ID.path;}
                    ];
                  };
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
                    password = {_secret = config.sops.secrets.singbox_hy2_pwd.path;};
                  }
                ];

                tls = {
                  enabled = true;
                  server_name = hy2Domain;
                  alpn = ["h3"];
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
              {outbound = "direct";}
            ];
          };
        };
      };

      # 放行端口
      networking.firewall.allowedTCPPorts = [port];
      networking.firewall.allowedUDPPorts = lib.optionals hy2Enabled [hy2Port];
    }
    (mkIf hy2Enabled {
      security.acme.acceptTerms = mkDefault true;
      security.acme.certs."${hy2Domain}" = {
        email = myvars.mail;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.acme_cloudflare_env.path;
        group = "sing-box";
        # 证书更新后自动 reload，避免 HY2 继续使用旧证书
        reloadServices = ["sing-box.service"];
      };
    })
  ]);
}
