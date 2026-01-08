{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.singbox-server;
  port = 8443;
  # 伪装握手目标域名（随便换一个稳定的大站都行）
  handshakeServer = "www.bing.com";
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

    # !!!
    # 1. 注意里面的 `sops` + `_secret` 写法。先后尝试了几种写法（sops直接从 uuid = config.sops. 读取secret，但是这里不接受 filepath，只要明文secret，所以在evaluate时就失败。之后换成了 sops template写法和从 /run/secrets/xxx里直接 builtins.readFile（这个写法需要本地先有相应文件） ）

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
  };
}
