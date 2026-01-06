{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  servers = [
    {
      tag = "vps-103";
      server = "103.85.224.63";
      port = 8443;
    }
    {
      tag = "vps-142";
      server = "142.171.154.61";
      port = 8443;
    }
  ];
  secrets = {
    uuid = config.sops.placeholder.singboxUUID;
    publicKey = config.sops.placeholder.singboxPubKey;
    shortId = config.sops.placeholder.singboxID;
  };
  configJson = import ../../../lib/singbox-config.nix (secrets // {inherit servers;});
  clientConfigPath = config.sops.templates."singbox-client.json".path;
in {
  # Sing-box Module - System-level Proxy Service
  #
  # Sing-box requires root privileges to create TUN interfaces.
  # Configuration file is fixed at /etc/sing-box/config.json

  # https://mynixos.com/nixpkgs/options/services.sing-box

  # PLAN [2025-12-18] 暂时还是直接curl把配置拉到本地，直接run。之后再考虑用下面这种写法（）。注意，我需要让mac和nixos复用singbox的config.json，但是只有nixos有singbox的options支持，那么就需要
  # 归根到底，现在singbox client的主流方案就两种，用 services.sing-box 或者 直接 systemd里跑 sing-box run. 前者更nix，但是代价是1、所有outbounds也会直接写入到 /nix/store 里。2、动态outbounds很麻烦，只有在 systemd曾插入hook这么一种方案（否则只能放弃动态更新，直接写死到settings里，如果是自建节点，可以考虑这么处理，但是机场则不行）

  # 1、在 mac 和 nixos 之间复用
  # 2、定期 curl subscribe url, extract outbounds.
  # 3. 合并 静态 + 动态outbounds
  # 4. 把 update跟 singbox 解耦。更新失败直接使用之前的config.json 。所以update里做了原子写，不会直接替换目标path的config.json

  # 目标path的选择
  #  - /tmp 会被系统清理或重启消失，不保证持久；sing-box 服务如果在启动时读不到它会失败。
  #  - /run 也是临时的，但适合“运行时生成”的文件；系统启动时由 service 生成。
  #  - /var/lib/private（或 StateDirectory）是持久的，适合保存“上次成功的 outbounds”。
  #  - /etc 更像“静态配置”，不建议用来写入运行时生成文件。
  # 结论：你现在用 /tmp 能跑，但可靠性最差；建议至少换到 /var/lib（持久）或 /run（临时但可控）。

  # https://raw.githubusercontent.com/sunziping2016/flakes/refs/heads/master/modules/default/sing-box.nix TUN 客户端模块，动态合并 outbounds
  # https://raw.githubusercontent.com/tillycode/homelab/refs/heads/master/nixos/profiles/services/sing-box-router.nix 路由器侧（TUN + FakeIP + Clash API），算「客户端网关」
  # https://github.com/qbisi/nixos-config/blob/master/config/sing-box/client.nix  桌面/笔电侧客户端（TUN + tproxy，含 Clash API）

  # https://raw.githubusercontent.com/deltathetawastaken/dotfiles/refs/heads/main/pkgs/socks.nix 侧重多套 socks/http 代理与网命名空间，主要是客户端/跳板用
  # https://github.com/oluceps/nixos-config/blob/trival/modules/sing-box.nix  通用 service 包装（从凭据加载 config），不特指 server
  # https://github.com/penglei/nix-configs/blob/main/nixos/modules/sing-box-client.nix

  # 只有desktop才需要引入singbox（因为所有VPS默认本身都不需要挂singbox），所以放在这里
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box proxy service";
  };

  config = mkIf cfg.enable {
    # Install sing-box package
    environment.systemPackages = [
      pkgs.sing-box
    ];

    # 运行时渲染配置，避免密钥进入 /nix/store
    sops.templates."singbox-client.json".content = builtins.toJSON configJson;

    # Create systemd system service for sing-box (requires root for TUN interface)
    systemd.services.singbox = {
      description = "Sing-box Proxy Service";
      wantedBy = ["multi-user.target"];
      # 确保配置文件存在后再启动
      # FIXME 经常会遇到前面的 update-config 失败，导致singbox无法启动，这种问题怎么解决？
      # after = ["network-online.target" "singbox-update-config.service"];
      # requires = ["singbox-update-config.service"];

      serviceConfig = {
        Type = "simple";
        # 统一使用 cfg_path 指定的配置文件
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${clientConfigPath}";
        Restart = "always";
        RestartSec = "5s";

        # Security: Required capabilities for TUN interface
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_DAC_OVERRIDE";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_DAC_OVERRIDE";

        # Run as root (required for TUN interface creation)
        User = "root";

        # Minimal security hardening
        # Note: Cannot use ProtectHome or ProtectSystem=strict as they would
        # prevent reading config from /etc or accessing /home
        NoNewPrivileges = false; # Must be false for capabilities
        # 需访问宿主 /var/lib/sing-box/config.json，因此禁用 PrivateTmp
        PrivateTmp = false;
      };
    };

    # Ensure state dir exists with correct ownership before service start
    systemd.tmpfiles.rules = [
      "d /var/lib/sing-box 0700 root root -"
    ];
  };
}
