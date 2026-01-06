# https://sing-box.sagernet.org/configuration/
{
  # https://sing-box.sagernet.org/configuration/log/
  log = {
    disabled = true;
    # 设置为warn，防止日志喷涌
    level = "warn";
    # output = "box.log";
    timestamp = true;
  };

  # https://sing-box.sagernet.org/configuration/dns/
  dns = {
    independent_cache = true;
    strategy = "prefer_ipv4";
    fakeip = {
      enabled = true;
      inet4_range = "198.18.0.0/15";
      inet6_range = "fc00::/18";
    };
    rules = [
      # tailscale / NetBird 控制面 DNS 直连，防止 fakeip + TUN 抢路由
      # - tailscale.com / tailscale.io / ts.net: Tailscale 控制面 & DERP 域
      # - netbird.io / web.netbird.io: NetBird 控制面域
      # 用本地 DNS 返回真实地址，避免被 fakeip 改写成 198.18.0.0/15 或 fc00::/18，从而导致控制面握手走错路由。
      {
        domain_suffix = [
          "tailscale.com"
          "tailscale.io"
          "ts.net"
          "netbird.io"
          "web.netbird.io"
        ];
        server = "local";
        disable_cache = true;
      }
      {
        outbound = [
          "any"
        ];
        server = "local";
      }
      {
        disable_cache = true;
        rule_set = [
          "AdGuardSDNSFilter"
          "chrome-doh"
        ];
        server = "block";
      }
      {
        query_type = [
          "A"
          "AAAA"
        ];
        rewrite_ttl = 1;
        server = "fakeip";
      }
      {
        clash_mode = "global";
        server = "remote";
      }
      {
        clash_mode = "direct";
        server = "local";
      }
      {
        rule_set = "geosite-cn";
        server = "local";
      }
    ];

    #    rules = [
    #      {
    #        rule_set = "geosite-category-ads-all";
    #        server = "block";
    #        disable_cache = true;
    #      }
    #      {
    #        outbound = "any";
    #        server = "local";
    #      }
    #      {
    #        rule_set = [
    #          "geosite-geolocation-cn"
    #          "geosite-steam"
    #        ];
    #        server = "local";
    #      }
    #      # Will be changed to compiled rule sets in sing-box v1.8.0
    #      {
    #        domain_suffix = [
    #          "szp15.com"
    #          "aliyuncs.com"
    #        ];
    #        server = "local";
    #      }
    #      {
    #        query_type = [ "A" "AAAA" ];
    #        server = "remote";
    #      }
    #    ];

    servers = [
      # 自己新增的
      {
        address = "tls://8.8.8.8";
      }
      {
        address = "https://223.5.5.5/dns-query";
        detour = "select";
        tag = "remote";
      }
      {
        address = "https://223.5.5.5/dns-query";
        detour = "direct";
        tag = "local";
      }
      {
        address = "rcode://success";
        tag = "block";
      }
      {
        address = "fakeip";
        tag = "fakeip";
      }
    ];
  };

  # https://sing-box.sagernet.org/configuration/inbound/
  inbounds = [
    {
      address = [
        "172.19.0.1/30"
        "fdfe:dcba:9876::1/126"
      ];
      auto_route = true;
      endpoint_independent_nat = true;
      mtu = 9000;
      strict_route = true;
      type = "tun";
    }
    {
      listen = "127.0.0.1";
      listen_port = 2333;
      tag = "socks-in";
      type = "socks";
      users = [
      ];
    }
    {
      listen = "127.0.0.1";
      listen_port = 2334;
      tag = "mixed-in";
      type = "mixed";
      users = [
      ];
    }
  ];

  # https://sing-box.sagernet.org/configuration/route/
  route = {
    auto_detect_interface = true;
    # 用singbox官方srs的URL替换掉机场提供的
    rule_set = [
      # 无法直接访问gist，所以替换为下面的URL

      #      {
      #        tag = "geoip-cn";
      #        type = "remote";
      #        format = "binary";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs";
      #      }
      #      {
      #        tag = "geosite-geolocation-cn";
      #        type = "remote";
      #        format = "binary";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-cn.srs";
      #      }
      #      {
      #        tag = "geosite-steam";
      #        type = "remote";
      #        format = "binary";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-steam.srs";
      #      }
      #      {
      #        tag = "geosite-openai";
      #        type = "remote";
      #        format = "binary";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-openai.srs";
      #      }
      #      {
      #        tag = "geosite-category-ads-all";
      #        type = "remote";
      #        format = "binary";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs";
      #      }

      {
        format = "binary";
        tag = "geoip-cn";
        type = "remote";
        url = "http://sbx.lmd1n2s3.cc:21088/sbx/geoip-cn.srs";
        download_detour = "direct";
      }
      {
        format = "binary";
        tag = "geosite-cn";
        type = "remote";
        url = "http://sbx.lmd1n2s3.cc:21088/sbx/geosite-geolocation-cn.srs";
        download_detour = "direct";
      }
      {
        format = "binary";
        tag = "AdGuardSDNSFilter";
        type = "remote";
        url = "http://sbx.lmd1n2s3.cc:21088/sbx/AdGuardSDNSFilterSingBox.srs";
        download_detour = "direct";
      }
      {
        format = "source";
        tag = "chrome-doh";
        type = "remote";
        url = "http://sbx.lmd1n2s3.cc:21088/sbx/chrome-doh.json";
        download_detour = "direct";
      }
    ];
    rules = [
      # --- 路由规则优先顺序从上到下 ---
      # 直连 Tailscale / NetBird 控制与隧道网段，避免被 auto_route/strict_route 写入 table 2022：
      # - 域名：tailscale.com / tailscale.io / ts.net（控制面与 DERP），netbird.io / web.netbird.io（NetBird 控制面）
      # - 网段：
      #   * 100.64.0.0/10          -> Tailscale CGNAT 设备内网
      #   * fd7a:115c:a1e0::/48    -> Tailscale IPv6 前缀
      #   * 100.71.0.0/16          -> NetBird 默认 IPv4 网段（如控制面下发其他网段需追加）
      # 放在最前面，确保两类 overlay 的控制/数据走本地直连，不被 sing-box 改写或劫持默认路由。
      {
        domain_suffix = [
          "tailscale.com"
          "tailscale.io"
          "ts.net"
          "netbird.io"
          "web.netbird.io"
        ];
        outbound = "direct";
      }
      {
        ip_cidr = [
          "100.64.0.0/10" # Tailscale CGNAT 内网段
          "fd7a:115c:a1e0::/48" # Tailscale IPv6 前缀
          "100.71.0.0/16" # NetBird 默认下发 IPv4 网段
        ];
        outbound = "direct";
      }

      {
        action = "sniff";
      }
      {
        action = "hijack-dns";
        protocol = "dns";
      }
      {
        action = "resolve";
        strategy = "prefer_ipv4";
      }
      {
        clash_mode = "direct";
        outbound = "direct";
      }
      {
        clash_mode = "global";
        outbound = "select";
      }
      {
        ip_is_private = true;
        outbound = "direct";
      }
      {
        outbound = "direct";
        rule_set = "geoip-cn";
      }

      #        {
      #          protocol = "dns";
      #          outbound = "dns-out";
      #        }
      #        {
      #          ip_is_private = true;
      #          outbound = "direct";
      #        }
      #        {
      #          rule_set = [
      #            "geoip-cn"
      #            "geosite-geolocation-cn"
      #          ];
      #          outbound = "direct";
      #        }
      #        {
      #          rule_set = [
      #            "geosite-openai"
      #          ];
      #          outbound = "us";
      #        }
      #        {
      #          rule_set = "geosite-category-ads-all";
      #          outbound = "block";
      #        }
    ];
  };

  # https://sing-box.sagernet.org/configuration/experimental/
  experimental = {
    # 运行时持久化/缓存。可减轻 DNS/路由重建开销
    #    cache_file = {
    #      enabled = true;
    #      path = "/var/cache/sing-box/cache.db";
    #      store_fakeip = true;
    #    };
    clash_api = {
      external_controller = "127.0.0.1:9090";
      secret = "";
    };
  };

  # NOTE: outbounds are intentionally omitted; they are supplied at runtime from subscription.
  outbounds = [
    # urltest 组（自动测延迟选最优，目前只有一个节点，但结构保留方便以后加）
    {
      tag = "urltest";
      type = "urltest";
      use_all_provider = false;
      outbounds = ["my-reality"];
      url = "http://www.gstatic.com/generate_204";
      interval = "30s";
      tolerance = "50ms";
      # 可选：如果想更快切换失败节点
      # lazy = true;
      # fast_timeout = "5s";
    }

    # selector 组（手动选择节点，在 Clash 面板里可以看到）
    {
      tag = "select";
      type = "selector";
      default = "my-reality"; # 默认走自建节点
      outbounds = [
        "my-reality"
        "urltest"
        "direct"
        "block"
      ];
      # 可选：让面板显示更清晰
      # interrupt_exist_connections = false;
    }

    # 直连
    {
      tag = "direct";
      type = "direct";
    }

    # 阻止（备用）
    {
      tag = "block";
      type = "block";
    }

    # DNS 出站（sing-box 推荐显式定义）
    {
      tag = "dns-out";
      type = "dns";
    }

    {
      tag = "my-reality";
      type = "vless";
      server = "47.79.17.202";
      server_port = 10022;
      uuid = "d41ecf77-65c7-401f-8179-4051f2957317";
      flow = "xtls-rprx-vision";
      packet_encoding = "xudp"; # 推荐开启，提升 NAT 类型兼容性
      tls = {
        enabled = true;
        server_name = "aws.amazon.com";
        insecure = false; # Reality 不需要 insecure
        utls = {
          enabled = true;
          fingerprint = "chrome";
        };
        reality = {
          enabled = true;
          public_key = "C5TKrrkCJvo2ELaK4hNFrCJQdH2R2wKXh1FRJSCnMEM";
          # short_id 如果服务器端没配就留空
          # short_id = "";
        };
      };
    }
  ];
}
