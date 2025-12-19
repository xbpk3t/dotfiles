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
      {
        tag = "geoip-cn";
        type = "remote";
        format = "binary";
        url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs";
      }
      {
        tag = "geosite-geolocation-cn";
        type = "remote";
        format = "binary";
        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-cn.srs";
      }
      {
        tag = "geosite-steam";
        type = "remote";
        format = "binary";
        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-steam.srs";
      }
      {
        tag = "geosite-openai";
        type = "remote";
        format = "binary";
        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-openai.srs";
      }
      {
        tag = "geosite-category-ads-all";
        type = "remote";
        format = "binary";
        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs";
      }
    ];
    rules = [
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
    cache_file = {
      enabled = true;
      path = "/var/cache/sing-box/cache.db";
      store_fakeip = true;
    };
    clash_api = {
      external_controller = "127.0.0.1:9090";
      secret = "";
    };
  };

  # NOTE: outbounds are intentionally omitted; they are supplied at runtime from subscription.
}
