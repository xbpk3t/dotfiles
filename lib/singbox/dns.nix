# https://sing-box.sagernet.org/configuration/dns/
# https://sing-box.sagernet.org/manual/proxy/client/#basic-tun-usage-for-chinese-users
{
  # 开启后会让每个 DNS 服务器缓存独立，但会轻微降低性能。
  independent_cache = true;
  reverse_mapping = true;
  # 兜底解析器改为 remote，避免未命中规则时回落到本地 upstream。
  # 这里的 remote 仍然会通过 detour=select 出站，保持 anti-poisoning。
  final = "remote";

  strategy = "prefer_ipv4";

  # DNS 规则顺序决定优先级，把“必须直连的域名”放在最前面。
  #
  # - 被封锁/限制的域名在每个国家都不一样（政策、法律、监管机构不同）。
  # - 规则集的来源也不同，有的来自官方黑名单抓取，有的来自社区维护。
  # - 很多列表按“用途/主题”划分：广告、跟踪、成人、流媒体解锁、国家审查等，不是
  #   通用一份。
  #
  #
  #
  # [2026-01-20] antizapret 这个 rule_set 适用于绕过俄罗斯的域名封锁/审查，用不到
  rules = [
    # 重要：GitHub 域名必须返回真实 IP，不能走 FakeIP
    # 否则会解析到 198.18.0.0/15 或 fc00::/18，导致集群内访问超时（如 Flux 拉取仓库失败）
    {
      domain_suffix = [
        "github.com"
        "githubusercontent.com"
        "githubassets.com"
        "github.io"
      ];
      # 这里走远端解析，但会通过代理出站（由 remote 的 detour 决定），可避免国内污染
      server = "remote";
      # 避免缓存污染，确保更新后立即生效
      disable_cache = true;
    }
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
    # Clash 模式优先于 FakeIP 兜底：
    # - direct 模式返回 real IP（local）
    # - global 模式走 remote 解析
    # 这样可以避免模式切换后依旧拿到 stale FakeIP。
    {
      clash_mode = "direct";
      query_type = [
        "A"
        "AAAA"
      ];
      server = "local";
      disable_cache = true;
    }
    {
      clash_mode = "global";
      query_type = [
        "A"
        "AAAA"
      ];
      server = "remote";
      disable_cache = true;
    }

    # CN 域名优先返回 real IP（local），避免全部落入 FakeIP 池。
    # 这条规则必须放在 FakeIP 前面，否则会被 query_type=A/AAAA 先匹配。
    {
      rule_set = "geosite-geolocation-cn";
      query_type = [
        "A"
        "AAAA"
      ];
      server = "local";
      disable_cache = true;
    }

    # A/AAAA 的最终兜底：走 FakeIP（仅处理未被上面规则命中的域名）。
    # 重点：保持这条在规则靠后位置，避免“全量域名都 FakeIP”。
    {
      query_type = [
        "A"
        "AAAA"
      ];
      rewrite_ttl = 1;
      server = "fakeip";
    }
  ];

  # 不需要全部保留。最少可用集通常是：
  # - fakeip（TUN 必需）
  # - local（国内解析）
  # - remote（外站解析，且必须走代理 detour）
  # - tx（给 DoH 解析做 bootstrap / fallback）
  # 其它比如 udp 1.1.1.1、DoT 8.8.8.8、google/cloudflare DoH 都是“备选/冗余”，保留是为了故障转移或调试方便。
  servers = [
    # Plain UDP resolver (Cloudflare 1.1.1.1).
    # Use only as a simple fallback; UDP is easiest to intercept/poison on hostile networks.
    {
      type = "udp";
      server = "1.1.1.1";
    }
    # FakeIP pool definition for TUN mode.
    # All A/AAAA lookups mapped to this pool when rule selects "fakeip".
    {
      type = "fakeip";
      tag = "fakeip";
      inet4_range = "198.18.0.0/15";
      inet6_range = "fc00::/18";
    }

    # DNS-over-TLS to Google (8.8.8.8:853).
    # Encrypts DNS, but still a direct egress unless you add a detour.
    {
      type = "tls";
      server = "8.8.8.8";
    }

    # Google DNS-over-HTTPS endpoint.
    # Uses "tx" to resolve dns.google via a domestic resolver to avoid bootstrap failures.
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

    # Cloudflare DNS-over-HTTPS endpoint.
    # Also bootstrapped via "tx" so the DoH hostname resolves locally first.
    {
      type = "https";
      tag = "cloudflare-dns";
      server = "1.1.1.1";
      path = "/dns-query";
      domain_resolver = {
        server = "tx";
        strategy = "ipv4_only";
      };
    }

    # Domestic DoH resolver used for bootstrap and CN domain resolution.
    # Keep this reachable without proxy to avoid circular dependency.
    {
      type = "https";
      tag = "tx";
      server = "223.5.5.5";
      path = "/dns-query";
    }

    # "local" DNS tag: domestic DoH resolver for CN domains and direct mode.
    # Typically used by rules like geosite-cn or clash_mode=direct.
    {
      type = "https";
      tag = "local";
      server = "223.5.5.5";
      path = "/dns-query";
    }
    # "remote" DNS tag: 用于 foreign domains / global mode。
    # 这里改为 Cloudflare DoH + detour=select，和 local(223.5.5.5)彻底解耦，
    # 避免 local/remote 同 upstream 带来的语义混乱与故障联动。
    {
      type = "https";
      tag = "remote";
      server = "1.1.1.1";
      path = "/dns-query";
      detour = "select";
    }
  ];
}
