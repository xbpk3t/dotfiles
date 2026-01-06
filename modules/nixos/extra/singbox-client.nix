{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  cfg_path = "/var/lib/sing-box/config.json";
  outbounds_path = "/var/lib/sing-box/outbounds.json";
  baseJson = pkgs.writeText "singbox-base.json" (builtins.toJSON (import ../../../lib/singbox-config.nix));
  updateScript = pkgs.writeScriptBin "singbox-update" ''
    #!${pkgs.nushell}/bin/nu
    ${builtins.readFile ../../../.taskfile/mac/singbox/update-config.nu}
  '';
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
      pkgs.curl
      pkgs.jq
    ];

    # 使用 Task 下载订阅配置，解耦主服务
    systemd.services.singbox-update-config = {
      description = "Update Sing-box Configuration from Subscription URL";
      # 最多重试 3 次
      startLimitBurst = 3;
      # 1 小时内最多重试 3 次
      startLimitIntervalSec = 3600;
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      # Expose required tools to the service
      environment = {
        PATH = lib.mkForce "/run/current-system/sw/bin:/run/wrappers/bin";
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${updateScript}/bin/singbox-update --url-file ${config.sops.secrets.singboxUrl.path} --base ${baseJson} --config ${cfg_path} --outbounds ${outbounds_path}";
        # Treat curl timeout (28) as non-fatal so activation doesn't roll back; timer will retry.
        SuccessExitStatus = [0 1 28];
        TimeoutStartSec = "2min";
      };
    };

    # Systemd timer to update sing-box configuration every 12 hours
    systemd.timers.singbox-update-config = {
      description = "Timer for Sing-box Configuration Update";
      wantedBy = ["timers.target"];

      timerConfig = {
        # 系统启动后 5 分钟首次运行
        OnBootSec = "5min";
        # 之后每 12 小时运行一次
        OnUnitActiveSec = "12h";
        # 如果错过了运行时间，立即运行
        Persistent = true;
        # 添加随机延迟 0-30 分钟，避免所有机器同时请求
        RandomizedDelaySec = "30min";
      };
    };

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
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${cfg_path}";
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
