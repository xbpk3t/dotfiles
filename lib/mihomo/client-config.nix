{
  config,
  pkgs,
  lib,
  mylib,
  wildUrl,
  ...
}:
with lib; let
  inventory = mylib.inventory."nixos-vps";
  nodes = inventory;
  servers = lib.lists.filter (s: s != null) (
    lib.attrsets.mapAttrsToList (
      name: node:
        if node ? singbox
        then
          node.singbox
          // {
            hostName = node.hostName or name;
            server = node.singbox.server or (mylib.inventory.primaryHostForNode name node);
          }
        else null
    )
    nodes
  );

  # mihomo 的 nixpkgs 模块只接受 configFile (路径)，不支持 native Nix settings。
  # 所以所有平台统一用 sops template 渲染完整 JSON，无需像 singbox 那样按 isDarwin 分支。
  secrets = {
    uuid = config.sops.placeholder.SINGBOX_UUID;
    publicKey = config.sops.placeholder.SINGBOX_PUB_KEY;
    shortId = config.sops.placeholder.SINGBOX_ID;
    password = config.sops.placeholder.SINGBOX_PWD;
    clashSecret = config.sops.placeholder.SINGBOX_CLASH_SK;
  };

  outbounds = import ./outbounds.nix {
    inherit servers lib;
    inherit (secrets) uuid publicKey shortId password;
  };

  # 参考 iKuuu_V2.yaml / 雷霆.yaml 的静态模板结构
  # 节点不再硬编码进 proxies，而是拆成两个 provider：
  #   self —— file provider，由 selfProviderContent 渲染到 providers/self.yaml
  #   wild —— http provider，mihomo 周期性从 Sub-Store 拉取
  configAttrset = {
    mode = "rule";
    log-level = "info";
    ipv6 = true;
    external-controller = "0.0.0.0:9090";
    secret = secrets.clashSecret;
    external-ui = "${pkgs.metacubexd}";
    mixed-port = 7890;
    allow-lan = true;
    bind-address = "*";

    tun = {
      enable = true;
      stack = "system";
      auto-route = true;
      auto-detect-interface = true;
      dns-hijack = ["any:53"];
    };

    dns = {
      enable = true;
      ipv6 = true;
      enhanced-mode = "fake-ip";
      fake-ip-range = "198.18.0.1/16";
      fake-ip-filter = [
        "*.lan"
        "*.local"
      ];
      default-nameserver = [
        "223.5.5.5"
        "119.29.29.29"
      ];
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
        ipcidr = ["240.0.0.0/4"];
      };
    };

    proxy-providers = {
      self = {
        type = "file";
        # 相对 -d /var/lib/mihomo；mihomo 文档允许相对路径
        path = "providers/self.yaml";
        health-check = {
          enable = true;
          url = "https://cp.cloudflare.com/generate_204";
          interval = 300;
        };
      };
      wild = {
        type = "http";
        # wildUrl 是模板字符串，其中 __ADMIN_PATH__ 在 sops template 渲染阶段
        # 由 sops-nix 自动替换成 ME_SK 的真实值（与 axonhub DEFAULT_SK 同源）。
        # 这样 admin path 永不进 /nix/store。
        url = lib.replaceStrings ["__ADMIN_PATH__"] [config.sops.placeholder.ME_SK] wildUrl;
        path = "providers/wild.yaml";
        interval = 1800;
        health-check = {
          enable = true;
          url = "https://cp.cloudflare.com/generate_204";
          interval = 600;
        };
      };
    };

    proxy-groups = [
      {
        name = "Manual";
        type = "select";
        proxies = ["Self" "Wild" "Auto" "DIRECT"];
      }
      {
        name = "Self";
        type = "url-test";
        use = ["self"];
        url = "https://cp.cloudflare.com/generate_204";
        interval = 300;
      }
      {
        name = "Wild";
        type = "url-test";
        use = ["wild"];
        url = "https://cp.cloudflare.com/generate_204";
        interval = 600;
      }
      {
        name = "Auto";
        type = "fallback";
        proxies = ["Self" "Wild" "DIRECT"];
        url = "https://cp.cloudflare.com/generate_204";
        interval = 300;
      }
    ];

    rules =
      [
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
        "DOMAIN-SUFFIX,github.com,Manual"
        "DOMAIN-SUFFIX,githubusercontent.com,Manual"
        "DOMAIN-SUFFIX,githubassets.com,Manual"
        "DOMAIN-SUFFIX,google.com,Manual"
        "DOMAIN-SUFFIX,youtube.com,Manual"
        "DOMAIN-SUFFIX,ytimg.com,Manual"
        "DOMAIN-SUFFIX,twimg.com,Manual"
        "DOMAIN-SUFFIX,docker.com,Manual"
        "DOMAIN-SUFFIX,cache.nixos.org,Manual"

        # CN 域名直连
        "DOMAIN-SUFFIX,cn,DIRECT"
        "DOMAIN-KEYWORD,-cn,DIRECT"

        # 国内大站直连
        "DOMAIN-SUFFIX,baidu.com,DIRECT"
        "DOMAIN-SUFFIX,bilibili.com,DIRECT"
        "DOMAIN-SUFFIX,taobao.com,DIRECT"
        "DOMAIN-SUFFIX,alipay.com,DIRECT"
        "DOMAIN-SUFFIX,qq.com,DIRECT"
        "DOMAIN-SUFFIX,weibo.com,DIRECT"
        "DOMAIN-SUFFIX,zhihu.com,DIRECT"
        "DOMAIN-SUFFIX,jd.com,DIRECT"
        "DOMAIN-SUFFIX,163.com,DIRECT"
        "DOMAIN-SUFFIX,netease.com,DIRECT"

        # GEOIP CN 直连
        "GEOIP,CN,DIRECT"

        # 本地域名直连
        "DOMAIN-SUFFIX,local,DIRECT"
        "DOMAIN-SUFFIX,lan,DIRECT"

        # 兜底
        "MATCH,Manual"
      ];
  };

  templatesContent = builtins.toJSON configAttrset;

  # self provider 文件由调用方写到 providers/sub-store 风格的 yaml 中
  # 这里只导出 proxies 列表，结构同 ClashMeta provider 规范
  selfProviderContent = builtins.toJSON {
    proxies = outbounds.proxies;
  };
in {
  inherit templatesContent selfProviderContent;
}
