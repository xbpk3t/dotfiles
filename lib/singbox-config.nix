{
  servers,
  uuid,
  publicKey,
  shortId,
  sni ? "www.bing.com",
  flow ? "xtls-rprx-vision",
  fingerprint ? "chrome",
  packetEncoding ? "xudp",
}:
# https://sing-box.sagernet.org/configuration/
# [Sing-box realip配置方案 - 开发调优 - LINUX DO](https://linux.do/t/topic/175470)
# https://github.com/MetaCubeX/meta-rules-dat
# [最好用的 sing-box 一键安装脚本 - 233Boy](https://233boy.com/sing-box/sing-box-script/)
# https://linux.do/t/topic/1146113/5
# 注意
# 1、未配置
## certificate (若需要屏蔽某些 CA 或使用 Mozilla/Chrome 根证书列表，可显式配置。不配置时使用系统证书存储。)
## endpoints (通常用于 WireGuard/Tailscale 等系统接口。未使用即可保持为空。)
let
  toOutbound = s: let
    base = {
      type = "vless";
      tag = s.tag;
      server = s.server;
      server_port = s.port;
      uuid = uuid;
      flow = flow;
      tls = {
        enabled = true;
        server_name = sni;
        utls = {
          enabled = true;
          fingerprint = fingerprint;
        };
        reality = {
          enabled = true;
          public_key = publicKey;
          short_id = shortId;
        };
      };
    };
  in
    if packetEncoding == null
    then base
    else base // {packet_encoding = packetEncoding;};
in {
  # https://sing-box.sagernet.org/configuration/log/
  log = {
    # 开启便于debug
    disabled = false;
    # 设置为warn，防止日志喷涌. 改为info
    level = "info";
    # 注意这个log path跟systemd本身生成的log不是一码事。如果不设置这个path，systemd生成的日志没有timestamp，很难排查问题
    output = "/tmp/singbox.log";
    timestamp = true;
  };

  # https://sing-box.sagernet.org/configuration/dns/
  dns = {
    # 开启后会让每个 DNS 服务器缓存独立，但会轻微降低性能。
    independent_cache = true;
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
        detour = "direct";
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
        detour = "direct";
      }
      # 新写法（远端 DNS tag，用于全局模式）
      {
        type = "https";
        tag = "remote";
        server = "223.5.5.5";
        path = "/dns-query";
        detour = "select";
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
      tag = "tun-in";
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

  # https://sing-box.sagernet.org/configuration/experimental/
  experimental = {
    # 运行时持久化/缓存。可减轻 DNS/路由重建开销
    # 可缓存 rule-set 与 fakeip，重启更稳定（比如说如果设置为false，那么每次启动singbox，都会重新拉取rule-set，如果拉取失败，服务本身就起不来）
    cache_file = {
      enabled = true;
      store_fakeip = true;
      store_rdrc = true;
      # path = "/var/cache/sing-box/cache.db";
    };
    clash_api = {
      external_controller = "127.0.0.1:9090";
      # Clash API 若监听在 0.0.0.0，官方强烈要求设置 secret。但是这里为了省事，所以不设置
      # Clash API 如果开放到非本机地址必须设置 `secret`
      secret = "";
    };
  };

  # 未配置即默认禁用；可在系统时间不可靠时提供时间同步服务
  ntp = {
    enabled = false;
    server = "time.apple.com";
    server_port = 123;
    interval = "30m";
  };

  # https://sing-box.sagernet.org/configuration/route/
  route = {
    # TUN场景需要开启该配置，以减少路由回环风险
    auto_detect_interface = true;

    # dns.final 和 route.final 为空时都会退回“第一个 server/outbound”，建议显式配置以避免隐式行为
    final = "";
    # 新写法：作为全局默认域名解析器，替代 outbound DNS rule item
    default_domain_resolver = "local";

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

      #      {
      #        format = "binary";
      #        tag = "geoip-cn";
      #        type = "remote";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs";
      #      }
      #      {
      #        format = "binary";
      #        tag = "geosite-geolocation-cn";
      #        type = "remote";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-cn.srs";
      #      }
      #      {
      #        format = "binary";
      #        tag = "geosite-steam";
      #        type = "remote";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-steam.srs";
      #      }
      #      {
      #        format = "binary";
      #        tag = "geosite-openai";
      #        type = "remote";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-openai.srs";
      #      }
      #      {
      #        format = "binary";
      #        tag = "geosite-category-ads-all";
      #        type = "remote";
      #        url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs";
      #      }
      #      {
      #        format = "binary";
      #        tag = "AdGuardSDNSFilter";
      #        type = "remote";
      #        url = "http://sbx.lmd1n2s3.cc:21088/sbx/AdGuardSDNSFilterSingBox.srs";
      #        download_detour = "direct";
      #      }
      #      {
      #        format = "source";
      #        tag = "chrome-doh";
      #        type = "remote";
      #        url = "http://sbx.lmd1n2s3.cc:21088/sbx/chrome-doh.json";
      #        download_detour = "direct";
      #      }

      {
        format = "binary";
        tag = "geoip-cn";
        type = "remote";
        url = "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/cn.srs"; # 或 geoip-cn.srs，根据实际仓库文件
      }
      {
        format = "binary";
        tag = "geosite-geolocation-cn"; # MetaCubeX 对应为 geosite-cn 或 geosite-geolocation-!cn（反向，非CN）
        type = "remote";
        url = "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/cn.srs";
      }
      {
        format = "binary";
        tag = "geosite-steam";
        type = "remote";
        url = "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/steam.srs"; # 如果无，fallback 到 SagerNet 或自定义合并
      }
      {
        format = "binary";
        tag = "geosite-openai";
        type = "remote";
        url = "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/openai.srs";
      }
      {
        format = "binary";
        tag = "geosite-category-ads-all";
        type = "remote";
        url = "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/category-ads-all.srs";
      }
    ];

    rules = [
      # 从机场的config.json里拿到的
      #      {
      #        action = "sniff";
      #      }
      #      {
      #        action = "hijack-dns";
      #        protocol = "dns";
      #      }
      #      {
      #        action = "resolve";
      #        strategy = "prefer_ipv4";
      #      }
      #      {
      #        clash_mode = "direct";
      #        outbound = "direct";
      #      }
      #      {
      #        clash_mode = "global";
      #        outbound = "select";
      #      }
      #      {
      #        ip_is_private = true;
      #        outbound = "direct";
      #      }
      #      {
      #        outbound = "direct";
      #        rule_set = "geoip-cn";
      #      }

      {
        # 强制 cache.nixos.org 走自建节点（默认会默认直连，很慢）
        domain_suffix = ["cache.nixos.org"];
        outbound = "select";
      }
      {
        # 旧规则：所有 TUN 流量直接走 select，会导致国内站点也走代理
        # inbound = [
        #   "tun-in"
        # ];
        # outbound = "select";
      }
      {
        port = [
          443
        ];
        network = "tcp";
        outbound = "direct";
      }
      {
        rule_set = "geoip-cn";
        outbound = "direct";
      }
      {
        rule_set = [
          "geosite-geolocation-cn"
          "geosite-steam"
        ];
        outbound = "direct";
      }
      {
        # 新规则：让 CN 规则先命中，剩余的 TUN 流量再走 select
        inbound = [
          "tun-in"
        ];
        outbound = "select";
      }
    ];
  };

  # https://sing-box.sagernet.org/configuration/service/
  services = {};

  # 选择器，把多个自建节点聚合到一个入口
  outbounds = let
    outs = map toOutbound servers;
  in
    outs
    ++ [
      {
        type = "selector";
        tag = "select";
        outbounds = map (o: o.tag) outs;
        default = (builtins.head outs).tag;
      }
      {
        type = "direct";
        tag = "direct";
      }
    ];
}
