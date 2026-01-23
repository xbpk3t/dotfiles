# https://sing-box.sagernet.org/configuration/route/
{ruleSets}: {
  # TUN场景需要开启该配置，以减少路由回环风险
  auto_detect_interface = true;

  # dns.final 和 route.final 为空时都会退回“第一个 server/outbound”，建议显式配置以避免隐式行为
  # 默认走 selector，所以显示声明为走 select（这里跟）
  final = "select";

  # 新写法：作为全局默认域名解析器，替代 outbound DNS rule item
  default_domain_resolver = "local";

  rule_set = ruleSets;

  # direct规则要在任何可能把它们送进 select 的规则之前
  rules = [
    ############## 预处理（识别与改写） ##############
    # sniff：让后续 protocol 规则能命中（否则协议未知）
    {
      action = "sniff";
    }
    # DNS 劫持：TUN 场景尽早接管 DNS，避免回环
    {
      action = "hijack-dns";
      protocol = "dns";
    }

    ############## 强制直连（高优先级） ##############
    # [2026-01-09] 自建节点后，无法通过ssh连接到节点VPS。之前通过 ip_cidr 解决该问题。但是直接设置 protocol 是更好的方案
    #
    #
    # [2026-01-23] 发现即使有这个rule，ssh连接还是没有走direct，导致SSH 流量仍然被 sing-box 接管（SSH 流量 实际上是经由 sing-box 的hysteria2 inbound 再回环到 142.171.154.61:22），NixOS 切换时停掉 sing-box = SSH 立刻断开。发现是 sniff跟这条rule的顺序问题。
    #
    # 依赖 sniff：protocol 识别需要 sniff 先执行，否则可能不命中
    {
      protocol = [
        "bittorrent"
        "ssh"
        "rdp"
        "ntp"
      ];
      action = "route";
      outbound = "direct";
    }
    # 私网直连：避免局域网/内网走代理
    {
      ip_is_private = true;
      action = "route";
      outbound = "direct";
    }

    ############## 站点规则（域名定向） ##############
    # JetBrains Remote Dev / Toolbox downloads should bypass proxy to avoid TLS EOF/timeouts.
    # 注意加到了
    {
      domain_suffix = [
        "download.jetbrains.com"
        "download-cdn.jetbrains.com.cn"
        "jetbrains.com"
        "jetbrains.net"
      ];
      action = "route";
      outbound = "direct";
    }
    # 强制 cache.nixos.org 走自建节点（默认会默认直连，很慢）
    {
      domain_suffix = ["cache.nixos.org"];
      outbound = "select";
    }

    ############## 业务定向（明确例外） ##############
    # 注意这里
    {
      action = "route";
      rule_set = "geosite-openai";
      outbound = "select";
    }

    ############## 模式覆盖（手动开关） ##############
    {
      clash_mode = "direct";
      outbound = "direct";
    }
    {
      clash_mode = "global";
      outbound = "select";
    }

    ############## 地理规则（常规直连） ##############
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

    ############## 兜底规则（默认流量） ##############
    # 新规则：让 CN 规则先命中，剩余的 TUN 流量再走 select
    {
      inbound = [
        "tun-in"
      ];
      outbound = "select";
    }

    ############## 后处理（辅助解析） ##############
    {
      action = "resolve";
      strategy = "prefer_ipv4";
    }
  ];
}
