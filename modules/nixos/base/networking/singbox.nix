{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
in {
  #############################################################################
  # Sing-box Module - System-level Proxy Service
  #
  # Sing-box requires root privileges to create TUN interfaces.
  # Configuration file is fixed at /etc/sing-box/config.json
  #############################################################################

  # https://github.com/233boy/sing-box
  # [最好用的 sing-box 一键安装脚本 - 233Boy](https://233boy.com/sing-box/sing-box-script/)
  # https://github.com/yonggekkk/sing-box-yg
  # https://github.com/mack-a/v2ray-agent

  # [求一份在 macOS 上能用的 sing-box 1.12 的 tun 配置 - 开发调优 - LINUX DO](https://linux.do/t/topic/980110)
  # [sing-box 新手入门教程，使用配置、订阅转换方法攻略 | DUN.IM BLOG](https://blog.dun.im/anonymous/sing-box-dns-proxies-routes-rules-configuration-subscription-conversion-basic-tutorial.html)
  # [sing-box配置詳解 | 客户端服务器端配置 | 自行配置 - YouTube](https://www.youtube.com/watch?v=Mt3T2P9kybM)
  # [写给小白的自建科学上网教程：从技术原理到实践操作 - 深海幽域 / 深海幽域, Lv1 - LINUX DO](https://linux.do/t/topic/520757)
  # [从零开始：使用sbshell快速配置SingBox、sing-box使用的最佳方式、新手小白的福音、Linux透明网关 - YouTube](https://www.youtube.com/watch?v=aoSHzRitvC8)
  # [nsworld/nixos/services/sing-box.nix at 14909a50e9c6b40c65f5bbe2ebbbb2737f12a76d · zendo/nsworld](https://github.com/zendo/nsworld/blob/14909a50e9c6b40c65f5bbe2ebbbb2737f12a76d/nixos/services/sing-box.nix)
  # [【超级小白教程】迄今最简单的节点搭建！无需面板，复制粘贴搞定Sing-box服务端，从VPS选购到配置，手把手教你避坑，专业的搭建高速稳定节点 - YouTube](https://www.youtube.com/watch?v=tfYpMZ-gx8U)
  # [Sing-box节点搭建教程 | 2025最新保姆级教学，零基础自建VPS，高速稳定，畅享4K体验 - 七尺宇](https://www.qichiyu.com/750.html)
  # [OneBox/src/config/version_1_12/tun-config.ts at main · OneOhCloud/OneBox](https://github.com/OneOhCloud/OneBox/blob/main/src/config/version_1_12/tun-config.ts)
  # [抛弃猫咪，在 Windows 平台上拥抱 sing-box | 七夜 の Blog](https://blog.liqiye.com/posts/4111060364/index.html)
  # [小白也可用的sing-box配置json模板（适合裸核跑，PC、OpenWRT、iOS一把梭） - 文档共建 - LINUX DO](https://linux.do/t/topic/774500)

  # PLAN [2025-10-11] 与其自建节点，不如直接打野抓别人的节点。在自建之前先搞下这个。我感觉打野搭配 sub-store会很有用。
  # 【翻墙的终极解决方案】
  # 简单来说，就是 打野/机场 和 自建 互为灾备、互为冗余，具体来说，打野+自动扔进sub-store做测速（测速、筛选节点、删除无效节点等），自动按照latency排序，给我下发订阅URL（之后多端的singbox直接拉URL，本地不需要任何操作，默认使用）。
  # 打野（做中转, GroupPool）和自建（做落地鸡, GroupSelf）互为failover，两个其中任一挂了，直接另一个走直连。
  # 自建组两台机器，一台LA机器，DMIT大妈的的T1（我的主力落地鸡，美西节点，服务全开，¥37/年（折合来说¥12/月，比机场便宜），1C1G20GB1TB流量千兆带宽，网络好配置差，只做落地鸡（BWG 类似配置但是2C的机器$50/年）），另一台HK机器（备用落地鸡，我的主力VPS兼作落地，sub-store就在这台机器上跑，跑完把订阅URL分发到我所有workstation和homelab机器上）
  # 我的所有机器都直接走VLAN，不走公网，所以不需要担心被人打野

  # PLAN [2025-10-12] [singbox怎么用taskfile做切换节点操作？] 也就是类似于clashX这种GUI常用的选择节点。比如说有时需要自己按地区/国家选择节点

  # [faceair/clash-speedtest: clash speedtest](https://github.com/faceair/clash-speedtest) clash测速，仅供参考，用不到

  # [野王轮流坐，今天到你啦 - 开发调优 / 开发调优, Lv1 - LINUX DO](https://linux.do/t/topic/881775)
  #  [全自动获取免费机场节点/订阅方法分享【立即实现代理节点自由】 - 开发调优 / 开发调优, Lv1 - LINUX DO](https://linux.do/t/topic/38413)

  # 【配置 sub-store】
  # [搭 Docker版 Sub-Store 带 http-meta 实现 集合订阅 测延迟 排序 筛选 生成新订阅 定时任务上传Gist](https://zelikk.blogspot.com/2025/05/docker-sub-store-http-meta-gist.html)
  # [通过Docker在VPS上架设Sub-Store-整点猫咪](https://surge.tel/22/2953/)
  # [sub-store-org/Sub-Store: Advanced Subscription Manager for QX, Loon, Surge, Stash, Egern and Shadowrocket!](https://github.com/sub-store-org/Sub-Store)
  # [写了个 sub-store 的懒人配置 - 开发调优 - LINUX DO](https://linux.do/t/topic/660141)
  # [节点的订阅管理\分享-我的方案 - 资源荟萃 - LINUX DO](https://linux.do/t/topic/333959)
  # [sing-box 裸核运行指南+批量机场节点导入配置模板教程（适用 windows/OpenWRT） - 开发调优 - LINUX DO](https://linux.do/t/topic/770312)
  # [](https://raw.githubusercontent.com/Keywos/rule/main/rename.js)

  # [beck-8/subs-check: 订阅转换、测速、测活、流媒体检测、重命名、导出为任意格式的工具](https://github.com/beck-8/subs-check)

  #     experimental.cache_file = {
  #      enabled = true;
  #      path = "/var/cache/sing-box/cache.db";
  #      store_fakeip = true;
  #    };
  # https://github.com/qbisi/nixos-config/blob/master/config/sing-box/client.nix
  # https://github.com/sunziping2016/flakes/blob/master/modules/default/sing-box.nix

  # https://github.com/deltathetawastaken/dotfiles/blob/main/pkgs/socks.nix
  # https://github.com/sunziping2016/flakes/blob/master/modules/default/sing-box.nix
  # https://github.com/tillycode/homelab/blob/master/nixos/profiles/services/sing-box-router.nix
  # https://github.com/grizimin/.nixos/blob/master/modules/system/singbox.nix
  # https://github.com/oluceps/nixos-config/blob/trival/modules/sing-box.nix
  # https://github.com/penglei/nix-configs/blob/main/nixos/modules/sing-box-server.nix

  #     experimental.cache_file = {
  #      enabled = true;
  #      path = "/var/cache/sing-box/cache.db";
  #      store_fakeip = true;
  #    };
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box proxy service";
  };

  config = mkIf cfg.enable {
    # Install sing-box package
    environment.systemPackages = [pkgs.sing-box];

    # Create systemd system service for sing-box (requires root for TUN interface)
    # FIXME 替换为直接从 sub-store 的URL拉取
    systemd.services.sing-box = {
      description = "Sing-box Proxy Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        # Fixed configuration path - all machines use /etc/sing-box/config.json
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /etc/sing-box/config.json";
        Restart = "always";
        RestartSec = "5s";

        # Security: Required capabilities for TUN interface
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";

        # Run as root (required for TUN interface creation)
        User = "root";

        # Minimal security hardening
        # Note: Cannot use ProtectHome or ProtectSystem=strict as they would
        # prevent reading config from /etc or accessing /home
        NoNewPrivileges = false; # Must be false for capabilities
        PrivateTmp = true;
      };
    };
  };
}
