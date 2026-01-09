# https://sing-box.sagernet.org/configuration/route/
{ruleSets}: {
  # TUN场景需要开启该配置，以减少路由回环风险
  auto_detect_interface = true;

  # dns.final 和 route.final 为空时都会退回“第一个 server/outbound”，建议显式配置以避免隐式行为
  final = "";

  # 新写法：作为全局默认域名解析器，替代 outbound DNS rule item
  default_domain_resolver = "local";

  rule_set = ruleSets;

  rules = [
    # [2026-01-09] 自建节点后，无法通过ssh连接到节点VPS。之前通过 ip_cidr 解决该问题。但是直接设置 protocol是更好的方案
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
    {
      action = "sniff";
    }
    {
      action = "hijack-dns";
      protocol = "dns";
    }
    {
      action = "route";
      rule_set = "geosite-openai";
      outbound = "OpenAI";
    }
    # 从机场的config.json里拿到的
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
    {
      # 强制 cache.nixos.org 走自建节点（默认会默认直连，很慢）
      domain_suffix = ["cache.nixos.org"];
      outbound = "GLOBAL";
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
      outbound = "GLOBAL";
    }
  ];
}
