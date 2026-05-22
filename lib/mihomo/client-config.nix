{
  config,
  pkgs,
  lib,
  mylib,
  wildUrl,
  selfProviderTemplateName ? "mihomo-self-provider.yaml",
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

  # mihomo 只接受 configFile (路径)，不支持 native Nix settings。
  # 这里在构建期就把 attrset 直接渲染成 YAML，避免运行时再 yq 转换，也避免
  # 把 yq-go store path 写进 launchd plist 形成额外的 GC race 暴露面。
  #
  # 之所以用 pkgs.formats.yaml 而不是 builtins.toFile + runCommand + yq：
  # 1) pkgs.formats.yaml.generate 是 nixpkgs 官方的 settings 渲染器，
  #    其 passAsFile 机制天然保留 string context（不需要 unsafeDiscardStringContext）；
  # 2) 不再有"先 toJSON、再 toFile、再 yq"三层 boilerplate；
  # 3) 输出 derivation 的依赖关系由 nixpkgs 维护，避免我们在 lib 层自己造轮子时
  #    把 metacubexd 这类 store path 的 GC 追踪搞断。
  yamlFmt = pkgs.formats.yaml {};
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
        path = "/run/secrets/rendered/${selfProviderTemplateName}";
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

  # 这两段 readFile + yamlFmt.generate 仍然属于 IFD（import-from-derivation）：
  # eval 阶段会触发 remarshal/python 的 build。代价是 `nix flake check --no-build`
  # 之类的纯 eval 工作流会被打断。
  # 这里接受 IFD 的原因：
  # - 单 host 本地 darwin/nixos 切换场景下，eval 和 build 总是连在一起跑；
  # - 砍掉运行时 yq 转换是 Layer 4 的核心目标；
  # - pkgs.formats.yaml 的 build 闭包稳定（remarshal/pyyaml 都在 cache 里）。
  # 如果未来需要恢复纯 eval 工作流，备选方案是回退到 Layer 1 风格——
  # 把 yq 调用塞回 mihomo-tun-launcher，由 launchd 启动时再做 JSON→YAML。
  templatesContent = builtins.readFile (
    yamlFmt.generate "mihomo-config.yaml" configAttrset
  );

  selfProviderContent = builtins.readFile (
    yamlFmt.generate "mihomo-self-provider.yaml" {
      proxies = outbounds.proxies;
    }
  );
in {
  inherit templatesContent selfProviderContent;
}
