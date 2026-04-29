{
  config,
  pkgs,
  lib,
  mylib,
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
    hy2Password = config.sops.placeholder.SINGBOX_HY2_PWD;
    clashSecret = config.sops.placeholder.SINGBOX_CLASH_SK;
  };

  outbounds = import ./outbounds.nix {
    inherit servers lib;
    inherit (secrets) uuid publicKey shortId hy2Password;
  };

  # 参考 iKuuu_V2.yaml / 雷霆.yaml 的静态模板结构
  # 动态部分只有 proxies，其余 DNS / proxy-groups / rules 是固定的
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

    proxies = outbounds.proxies;

    proxy-groups = [
      {
        name = "Proxy";
        type = "select";
        proxies = ["auto"] ++ outbounds.tags;
      }
      {
        name = "auto";
        type = "url-test";
        proxies = outbounds.tags;
        url = "http://www.gstatic.com/generate_204";
        interval = 1800;
        tolerance = 50;
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
        # 必须代理的站点
        "DOMAIN-SUFFIX,openai.com,Proxy"
        "DOMAIN-SUFFIX,chatgpt.com,Proxy"
        "DOMAIN-SUFFIX,github.com,Proxy"
        "DOMAIN-SUFFIX,githubusercontent.com,Proxy"
        "DOMAIN-SUFFIX,githubassets.com,Proxy"
        "DOMAIN-SUFFIX,google.com,Proxy"
        "DOMAIN-SUFFIX,youtube.com,Proxy"
        "DOMAIN-SUFFIX,ytimg.com,Proxy"
        "DOMAIN-SUFFIX,twimg.com,Proxy"
        "DOMAIN-SUFFIX,docker.com,Proxy"
        "DOMAIN-SUFFIX,cache.nixos.org,Proxy"

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

        # 兜底代理
        "MATCH,Proxy"
      ];
  };

  templatesContent = builtins.toJSON configAttrset;
in {
  inherit templatesContent;
}
