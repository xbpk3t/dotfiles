{
  config,
  pkgs,
  lib,
  mylib,
  selfProviderTemplateName ? "mihomo-self-provider.yaml",
  tunExcludeUids ? [ ],
  extraRules ? [ ],
  ...
}:
with lib;
let
  # Fleet-wide：任何在 meta 里发布 `singbox` 的节点都是 client 的 server。
  # 不再硬编码 "nixos-vps" 组；未来 homelab / 其他平台加代理节点会自动进 outbounds。
  nodes = mylib.inventory.nodes;
  servers = lib.lists.filter (s: s != null) (
    lib.attrsets.mapAttrsToList (
      name: node:
      if node ? singbox then
        node.singbox
        // {
          hostName = node.hostName or name;
          server = node.singbox.server or (mylib.inventory.primaryHostForNode name node);
        }
      else
        null
    ) nodes
  );

  # mihomo 只接受 configFile (路径)，不支持 native Nix settings。
  # config 在 eval 阶段用 builtins.toJSON 渲染（JSON 是 YAML 1.2 子集，
  # mihomo 的 YAML parser 直接接受），避免 pkgs.formats.yaml 的 IFD——
  # 否则从 x86_64-linux 跑 deploy-rs / nix eval 时，会去 build 一个
  # aarch64-darwin 的 YAML derivation，直接 platform mismatch。
  secrets = {
    uuid = config.sops.placeholder.PROXY_UUID;
    publicKey = config.sops.placeholder.PROXY_PUB_KEY;
    shortId = config.sops.placeholder.PROXY_ID;
    password = config.sops.placeholder.PROXY_PWD;
    clashSecret = config.sops.placeholder.PROXY_CLASH_SK;
  };

  outbounds = import ./outbounds.nix {
    inherit servers lib;
    inherit (secrets)
      uuid
      publicKey
      shortId
      password
      ;
  };

  anyDnsServers = [
    "223.5.5.5"
    "119.29.29.29"
  ];

  # 参考 iKuuu_V2.yaml / 雷霆.yaml 的静态模板结构
  # 节点不再硬编码进 proxies，而是拆成两类 provider：
  #   self —— file provider，由 selfProviderContent 渲染到 providers/self.yaml
  #   wild —— http provider，mihomo 直接从各机场订阅 URL 拉取
  #
  # 订阅源自动发现：sops secrets 里所有 SUB_<NAME> 即一个机场源（key=源名，value=URL），
  # provider 名取 NAME 小写。新增机场只改 sops（secrets.yaml + secrets/default.nix），
  # 此处与 host 零改动。
  #
  # 订阅域名直连 + 排除代理：否则 mihomo 的 TUN + MATCH,Manual 兜底会把
  # 机场订阅域名也代理掉 → provider 拉订阅走自己 → DNS 自环 → EOF 拉取失败 → 全部节点挂。
  # 这些域名同时加入 fake-ip-filter，让解析直接走真实 DNS 而非 FakeIP。
  subDomains = lib.lists.unique (
    map (s: (builtins.elemAt (lib.splitString "/" (lib.removePrefix "https://" s.url)) 0)) wildSources
  );
  subDomainRules = map (d: "DOMAIN-SUFFIX,${d},DIRECT") subDomains;
  subDomainFakeIpFilter = map (d: "*.${d}") subDomains;
  wildSources = lib.attrsets.mapAttrsToList (name: _: {
    name = lib.strings.toLower (lib.strings.removePrefix "SUB_" name);
    url = config.sops.placeholder.${name};
  }) (lib.attrsets.filterAttrs (name: _: lib.strings.hasPrefix "SUB_" name) config.sops.secrets);

  # 每源一个独立 provider，策略组层面 use 合并成单一 Wild 池
  mkWildProvider = src: {
    type = "http";
    inherit (src) url;
    # mihomo 缓存目录，http provider 拉取失败时保留上次成功内容
    path = "/var/lib/mihomo/providers/${src.name}.yaml";
    interval = 1800;
    health-check = {
      enable = true;
      url = "https://cp.cloudflare.com/generate_204";
      interval = 600;
    };
    # Quick Setting Operator 等价物：强制所有节点 udp + skip-cert-verify
    override = {
      udp = true;
      skip-cert-verify = true;
    };
  };

  wildProviders = lib.listToAttrs (
    map (s: {
      inherit (s) name;
      value = mkWildProvider s;
    }) wildSources
  );
  wildNames = map (s: s.name) wildSources;
  configAttrset = {
    mode = "rule";
    log-level = "warning";
    ipv6 = true;
    external-controller = "0.0.0.0:9090";
    secret = secrets.clashSecret;
    external-ui = "${pkgs.zashboard}";
    mixed-port = 7890;
    allow-lan = true;
    bind-address = "*";

    tun = {
      enable = true;
      stack = "system";
      auto-route = true;
      auto-detect-interface = true;
      dns-hijack = [ "any:53" ];
    }
    // lib.optionalAttrs (tunExcludeUids != [ ]) {
      # derper 等 wildcard UDP 服务的回包按 UID 选路由；排除这些 UID，
      # 避免 STUN 回复被 mihomo 的 table 2022 接管。
      exclude-uid = tunExcludeUids;
    };

    dns = {
      enable = true;
      ipv6 = true;
      enhanced-mode = "fake-ip";
      fake-ip-range = "198.18.0.1/16";
      fake-ip-filter = [
        "*.lan"
        "*.local"
        # Mirrors the sing-box DNS rule: keep Tailscale control-plane names
        # out of FakeIP so tailscaled does not register through 198.18.x.x.
        "tailscale.com"
        "*.tailscale.com"
        "tailscale.io"
        "*.tailscale.io"
        "ts.net"
        "*.ts.net"
      ]
      ++ subDomainFakeIpFilter;
      nameserver-policy = {
        "+.tailscale.com" = anyDnsServers;
        "+.tailscale.io" = anyDnsServers;
        "+.ts.net" = anyDnsServers;
      };
      default-nameserver = anyDnsServers;
      nameserver = [
        "https://doh.pub/dns-query"
        "https://dns.alidns.com/dns-query"
      ];
      fallback = [
        "https://1.1.1.1/dns-query"
        "https://8.8.8.8/dns-query"
      ];
      fallback-filter = {
        geoip = true;
        geoip-code = "CN";
        ipcidr = [ "240.0.0.0/4" ];
      };
    };

    proxy-providers = {
      self = {
        type = "file";
        path = "/run/secrets/rendered/${selfProviderTemplateName}";
        health-check = {
          enable = true;
          url = "https://cp.cloudflare.com/generate_204";
          interval = 60;
        };
      };
    }
    // wildProviders;

    proxy-groups = [
      {
        name = "Manual";
        type = "select";
        proxies = [
          "Self"
          "Wild"
          "Auto"
          "DIRECT"
        ];
      }
      {
        name = "Self";
        type = "url-test";
        use = [ "self" ];
        url = "https://cp.cloudflare.com/generate_204";
        interval = 300;
      }
      {
        name = "Wild";
        type = "url-test";
        use = wildNames;
        url = "https://cp.cloudflare.com/generate_204";
        interval = 3600;
      }
      {
        name = "Auto";
        type = "fallback";
        proxies = [
          "Self"
          "Wild"
          "DIRECT"
        ];
        url = "https://cp.cloudflare.com/generate_204";
        interval = 1800;
      }
    ];

    rules =
      subDomainRules
      ++ [
        # 私网直连
        "IP-CIDR,127.0.0.0/8,DIRECT"
        "IP-CIDR,10.0.0.0/8,DIRECT"
        "IP-CIDR,172.16.0.0/12,DIRECT"
        "IP-CIDR,192.168.0.0/16,DIRECT"
        "IP-CIDR,100.64.0.0/10,DIRECT"
        "IP-CIDR,224.0.0.0/4,DIRECT"

        # SSH 避免回环（mihomo TUN 下的 SSH 流量走代理会导致循环依赖）
        "DST-PORT,22,DIRECT"

        # 代理节点 IP 直连（避免流量经代理再回连自己）
      ]
      ++ (map (s: "IP-CIDR,${s.server}/32,DIRECT,no-resolve") servers)
      ++ [
        # 必须代理的站点（统一走 Manual，由用户在 UI 上选 Self/Wild/Auto）
        "DOMAIN-SUFFIX,openai.com,Manual"
        "DOMAIN-SUFFIX,chatgpt.com,Manual"
        "DOMAIN-SUFFIX,grok.com,Manual"
        "DOMAIN-SUFFIX,github.com,Manual"
        "DOMAIN-SUFFIX,githubusercontent.com,Manual"
        "DOMAIN-SUFFIX,githubassets.com,Manual"
        "DOMAIN-SUFFIX,google.com,Manual"
        "DOMAIN-SUFFIX,youtube.com,Manual"
        "DOMAIN-SUFFIX,ytimg.com,Manual"
        "DOMAIN-SUFFIX,twimg.com,Manual"
        "DOMAIN-SUFFIX,docker.com,Manual"
        "DOMAIN-SUFFIX,linux.do,Manual"
        "DOMAIN-SUFFIX,cache.nixos.org,Manual"

        # CN 域名直连
        "DOMAIN-SUFFIX,cn,DIRECT"
        "DOMAIN-KEYWORD,-cn,DIRECT"

        # 国内大站直连
        "DOMAIN-SUFFIX,baidu.com,DIRECT"
        # "DOMAIN-SUFFIX,bilibili.com,DIRECT"
        "DOMAIN-SUFFIX,taobao.com,DIRECT"
        "DOMAIN-SUFFIX,alipay.com,DIRECT"
        "DOMAIN-SUFFIX,qq.com,DIRECT"
        "DOMAIN-SUFFIX,weibo.com,DIRECT"
        "DOMAIN-SUFFIX,jd.com,DIRECT"
        "DOMAIN-SUFFIX,163.com,DIRECT"
        "DOMAIN-SUFFIX,netease.com,DIRECT"
      ]
      # 主机/角色策略（host 层通过 extraRules 注入）。
      # 必须放在 GEOIP/MATCH 之前：域名规则先匹配，否则会被 GEOIP,CN 抢先。
      ++ extraRules
      ++ [
        # GEOIP CN 直连
        "GEOIP,CN,DIRECT"

        # 本地域名直连
        "DOMAIN-SUFFIX,local,DIRECT"
        "DOMAIN-SUFFIX,lan,DIRECT"

        # 兜底
        "MATCH,Manual"
      ];
  };

  # 纯 eval：不触发任何 derivation build。mihomo 接受 JSON 作为 YAML 配置。
  templatesContent = builtins.toJSON configAttrset;

  selfProviderContent = builtins.toJSON {
    inherit (outbounds) proxies;
  };
in
{
  inherit templatesContent selfProviderContent;
}
