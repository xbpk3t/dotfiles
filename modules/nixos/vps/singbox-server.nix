{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.singbox-server;
  port = 8443;
  #  hy2Port = 8444;
  # 伪装握手目标域名（随便换一个稳定的大站都行）
  handshakeServer = "www.bing.com";
  # HY2 证书对应的域名（需有有效证书）
  #  hy2ServerName = "hy2.example.com";
in {
  options.services.singbox-server = {
    enable = mkEnableOption "sing-box server (Reality)";
  };

  # vless+reality

  config = mkIf cfg.enable {
    # 通过以下命令生成 singbox node 的相应metadata，直接放到sops里，并且分发到所有nodes里。没必要分开配置，方便client端组装。
    # sing-box generate uuid
    # sing-box generate reality-keypair
    # sing-box generate rand 8 --hex

    # https://mynixos.com/nixpkgs/options/services.sing-box
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
                uuid = {_secret = config.sops.secrets.singboxUUID.path;};
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
                private_key = {_secret = config.sops.secrets.singboxPriKey.path;};

                # short_id 允许多个，这里只用一个
                short_id = [
                  {_secret = config.sops.secrets.singboxID.path;}
                ];
              };
            };
          }

          #        {
          #          type = "hysteria2";
          #          tag = "hysteria2";
          #          listen = "::";
          #          listen_port = hy2Port;
          #
          #          users = [
          #            {
          #              password = config.sops.secrets.singboxHy2Password.path;
          #            }
          #          ];
          #
          #          # 可按需调整带宽上限；留空则使用客户端默认
          #          up_mbps = 100;
          #          down_mbps = 100;
          #
          #          tls = {
          #            enabled = true;
          #            server_name = hy2ServerName;
          #            alpn = [ "h3" ];
          #            certificate_path = "/var/lib/acme/${hy2ServerName}/fullchain.pem";
          #            key_path         = "/var/lib/acme/${hy2ServerName}/key.pem";
          #          };
          #        }
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
    #  networking.firewall.allowedUDPPorts = [ hy2Port ];
  };
}
