# sm 轨 mihomo 代理客户端。
# 完整复用 lib/mihomo/client-config.nix（单一事实源，与 nixos 轨同一份逻辑）：
#   订阅自动发现（SUB_*）、自环防护、fake-ip、tailscale 排除、策略组。
# 用 sm 能力面表达 NixOS 的 services.mihomo：
#   sops.templates → sops-install-secrets 运行时渲染（placeholder 替换真实 secret）
#   users.users    → 静态 mihomo 用户（sm userborn 管理）
#   systemd.services.mihomo → 手写 unit（sm 能力面）
# 不做 services.resolved（NixOS 特有）；mihomo TUN 已 hijack DNS。
#
# ⚠️ 安全提醒（对抗式审查 S1/S3）：client-config.nix 是桌面/LAN 形态
# （allow-lan=true + bind-address="*" + mixed-port 无认证）。把它原样跑到
# 直连公网的 VPS 上，会把 7890/9090 变成公网开放代理暴露面；且 TUN 需要
# CAP_NET_ADMIN（否则 tun/auto-route/dns-hijack 静默失效）。因此在公网 VPS 上
# 启用时，必须 host 级收紧：
#   1) 绑定 loopback + allow-lan=false（仅 VPS 自身出网，走 TUN 透明代理），或
#   2) 绑定 tailnet/私网 IP + lan-allowed-ips 白名单（喂给信任客户端）
#   3) external-controller 绑 127.0.0.1（远程管理走 SSH 隧道）
# 并给 serviceConfig 补 AmbientCapabilities/CapabilityBoundingSet = CAP_NET_ADMIN。
# sm-vps-tc（SGP 直连公网）当前禁用本模块，见 hosts/sm-vps/default.nix。
#
# enable 开关：config.services.mihomo-client.enable（服务角色开关，默认 false）
# 对齐 nixos 轨 services.mihomo-server.enable / services.singbox-server.enable 命名。
# 依赖：sops.templates 渲染（mihomo-client.yaml 由 sops-install-secrets 生成）——
# 隐含依赖 modules/sm/sops.nix（基线 enable）。若未来 sops 可关，mihomo 需先确认。
{
  config,
  lib,
  mylib,
  pkgs,
  ...
}:
let
  cfg = config.services.mihomo-client;
in
{
  _file = ./mihomo.nix;

  options.services.mihomo-client = {
    enable = lib.mkEnableOption "mihomo proxy client (sm-vps)";
  };

  config = lib.mkIf cfg.enable (
    let
      # 完整复用 client-config.nix（与 nixos 轨同一份代理正确性逻辑）。
      # 路径：modules/sm/mihomo.nix → 上 2 层到仓库根 → lib/mihomo/client-config.nix
      client = import ../../lib/mihomo/client-config.nix {
        inherit config mylib lib pkgs;
        selfProviderTemplateName = "mihomo-self-provider.yaml";
      };
    in
    {
      # ── 静态 mihomo 用户（sops 渲染文件需显式 owner）──
      # 对应 nixos mihomo-client.nix 的 users.users.mihomo
      users.users.mihomo = {
        isSystemUser = true;
        group = "mihomo";
      };
      users.groups.mihomo = { };

      # ── sops 模板：运行时渲染（placeholder → 真实 secret）──
      # 与 nixos 侧一致：owner/group=mihomo，mode 0440（zashboard UI 可读）
      sops.templates."mihomo-client.yaml" = {
        content = client.templatesContent;
        owner = "mihomo";
        group = "mihomo";
        mode = "0440";
      };
      sops.templates."mihomo-self-provider.yaml" = {
        content = client.selfProviderContent;
        owner = "mihomo";
        group = "mihomo";
        mode = "0440";
      };

      # ── mihomo systemd unit（sm 能力面手写）──
      # 对应 nixos services.mihomo + systemd.services.mihomo
      # WorkingDirectory=/var/lib/mihomo 需目录先存在（tmpfiles 建），否则 CHDIR 失败。
      systemd.tmpfiles.rules = [
        "d /var/lib/mihomo 0755 mihomo mihomo - -"
        "d /var/lib/mihomo/providers 0755 mihomo mihomo - -"
      ];

      systemd.services.mihomo = {
        enable = true;
        description = "mihomo proxy client";
        after = [ "network-online.target" "sops-install-secrets.service" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "simple";
          User = "mihomo";
          Group = "mihomo";
          DynamicUser = false;
          # mihomo 默认写 $HOME/.config/mihomo；系统用户 HOME=/var/empty 不可写，
          # 设 HOME 到 /var/lib/mihomo（tmpfiles 已建，可写）。
          # mihomo 只允许 homedir + SAFE_PATHS 作为 external-ui/provider 源；
          # SAFE_PATHS 要含 zashboard store 路径 + /run/secrets/rendered。
          # 注意：systemd Environment 是 key=value 对，多个用多个 entry。
          Environment = [
            "HOME=/var/lib/mihomo"
            "SAFE_PATHS=${pkgs.zashboard}:/run/secrets/rendered"
          ];
          ExecStart = "${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f /run/secrets/rendered/mihomo-client.yaml";
          Restart = "on-failure";
          RestartSec = "5";
          WorkingDirectory = "/var/lib/mihomo";
        };
        wantedBy = [ "system-manager.target" ];
      };
    }
  );
}
