{...}: {
  # sing-box 代理配置
  services.sing-box = {
    enable = false;

    settings = {
      log = {
        level = "info";
        timestamp = true;
      };

      # DNS 配置 - 国内直连，国外走代理
      dns = {
        servers = [
          {
            tag = "cloudflare";
            address = "https://1.1.1.1/dns-query";
            detour = "proxy";
          }
          {
            tag = "local";
            address = "223.5.5.5";
            detour = "direct";
          }
        ];
        rules = [
          {
            outbound = ["any"];
            server = "local";
          }
          {
            rule_set = ["geosite-cn"];
            server = "local";
          }
        ];
        final = "cloudflare";
      };

      # 入站配置 - 本地代理
      #      inbounds = [
      #        {
      #          type = "mixed";
      #          tag = "mixed-in";
      #          listen = "127.0.0.1";
      #          listen_port = 1080;
      #        }
      #      ];

      # 出站配置 - 基础配置
      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
        # 代理节点需要根据订阅配置添加
      ];

      # 规则集配置 - 新版本 sing-box 要求使用 rule_set 替代直接的 geosite/geoip
      rule_set = [
        {
          tag = "geosite-cn";
          type = "remote";
          format = "binary";
          url = "https://github.com/SagerNet/sing-geoip/releases/latest/download/geosite-cn.srs";
          download_detour = "proxy";
        }
        {
          tag = "geoip-cn";
          type = "remote";
          format = "binary";
          url = "https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip-cn.srs";
          download_detour = "proxy";
        }
        {
          tag = "geoip-private";
          type = "remote";
          format = "binary";
          url = "https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip-private.srs";
          download_detour = "proxy";
        }
      ];

      # 路由规则
      route = {
        rules = [
          {
            rule_set = ["geosite-cn"];
            outbound = "direct";
          }
          {
            rule_set = ["geoip-private"];
            outbound = "direct";
          }
          {
            rule_set = ["geoip-cn"];
            outbound = "direct";
          }
        ];
        final = "proxy";
        auto_detect_interface = true;
      };
    };
  };

  # 订阅更新服务
  systemd.services.singbox-update = {
    enable = false;
    description = "更新 sing-box 订阅配置";
    script = ''
      mkdir -p /etc/sing-box
      curl -L "" \
        -o /etc/sing-box/config.json
      systemctl restart sing-box
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    wantedBy = ["multi-user.target"];
  };

  # 代理环境变量
  #  environment.sessionVariables = {
  #    HTTP_PROXY = "http://127.0.0.1:1080";
  #    HTTPS_PROXY = "http://127.0.0.1:1080";
  #    ALL_PROXY = "http://127.0.0.1:1080";
  #    no_proxy = "localhost,127.0.0.1,::1";
  #  };
}
