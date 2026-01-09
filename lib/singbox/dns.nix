# https://sing-box.sagernet.org/configuration/dns/
{
  # 开启后会让每个 DNS 服务器缓存独立，但会轻微降低性能。
  independent_cache = true;
  reverse_mapping = true;
  final = "remote";

  strategy = "prefer_ipv4";

  # DNS 规则顺序决定优先级，把“必须直连的域名”放在最前面。
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
    # 匹配任意出站的 DNS 请求都走本地 DNS（兜底规则，通常优先级较低）
    # any 指代的其实就是订阅中会鉴权的时候 一般提供的都是域名，而进行鉴权认证的时候，肯定要走国内的dns，不然也连接不到google的dns，所以需要有个 any
    # 旧写法（outbound DNS rule item）已废弃，将在 1.14 移除
    # {
    #   outbound = ["any"];
    #   server = "local";
    # }
    # 新写法在 route.default_domain_resolver 中设置（见 route）
    # 命中广告/DoH 规则集的域名直接返回成功码（等价于阻断解析）
    #      {
    #        disable_cache = true;
    #        rule_set = [
    #          "AdGuardSDNSFilter"
    #          "chrome-doh"
    #        ];
    #        server = "block";
    #      }
    # A/AAAA 查询返回 FakeIP，用于配合 TUN 劫持和透明代理
    {
      query_type = [
        "A"
        "AAAA"
      ];
      rewrite_ttl = 1;
      server = "fakeip";
    }
    # Clash 模式为 global 时，DNS 走远端解析（适合全局代理）
    {
      clash_mode = "global";
      server = "remote";
    }
    # Clash 模式为 direct 时，DNS 走本地解析（直连模式）
    {
      clash_mode = "direct";
      server = "local";
    }
    # 命中 geosite（CN）规则的域名走本地 DNS（此处对应 geosite-geolocation-cn）
    {
      rule_set = "geosite-geolocation-cn";
      server = "local";
    }
  ];

  servers = [
    # 自己新增的
    {
      type = "udp";
      server = "1.1.1.1";
    }
    # 之前的fakeip，整合到servers里了（新格式）
    {
      type = "fakeip";
      tag = "fakeip";
      inet4_range = "198.18.0.0/15";
      inet6_range = "fc00::/18";
    }
    # 旧写法（legacy DNS server）
    # {
    #   address = "tls://8.8.8.8";
    # }
    # 新写法（DoT）
    {
      type = "tls";
      server = "8.8.8.8";
    }

    # google doh（旧写法）
    # {
    #   tag = "google";
    #   address = "https://dns.google/dns-query";
    #   address_resolver = "tx";
    #   address_strategy = "ipv4_only";
    #   strategy = "ipv4_only";
    #   client_subnet = "1.0.1.0";
    # }
    # google doh（新写法）
    {
      type = "https";
      tag = "google";
      server = "dns.google";
      path = "/dns-query";
      domain_resolver = {
        server = "tx";
        strategy = "ipv4_only";
      };
    }
    # 腾讯提供的DNS查询服务（旧写法）
    # {
    #   address = "https://223.5.5.5/dns-query";
    #   detour = "direct";
    #   tag = "tx";
    # }
    # 腾讯提供的DNS查询服务（新写法）
    {
      type = "https";
      tag = "tx";
      server = "223.5.5.5";
      path = "/dns-query";
    }
    # 旧写法（legacy DNS server）
    # {
    #   address = "https://223.5.5.5/dns-query";
    #   detour = "direct";
    #   tag = "local";
    # }
    # 新写法（本地 DNS tag）
    {
      type = "https";
      tag = "local";
      server = "223.5.5.5";
      path = "/dns-query";
    }
    # 新写法（远端 DNS tag，用于全局模式）
    {
      type = "https";
      tag = "remote";
      server = "223.5.5.5";
      path = "/dns-query";
      # detour = "GLOBAL";
    }

    # 旧写法（rcode server 已废弃）
    # {
    #   address = "rcode://success";
    #   tag = "block";
    # }
    # 旧写法（legacy fakeip server）
    # {
    #   address = "fakeip";
    #   tag = "fakeip";
    # }
  ];
}
