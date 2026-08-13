# sm 轨 mihomo 代理客户端。
# 完整复用 lib/mihomo/client-config.nix（单一事实源，与 nixos 轨同一份逻辑）：
#   订阅自动发现（SUB_*）、自环防护、fake-ip、tailscale 排除、策略组。
# 用 sm 能力面表达 NixOS 的 services.mihomo：
#   sops.templates → sops-install-secrets 运行时渲染（placeholder 替换真实 secret）
#   users.users    → 静态 mihomo 用户（sm userborn 管理）
#   systemd.services.mihomo → 手写 unit（sm 能力面）
# 不做 services.resolved（NixOS 特有）；mihomo TUN 已 hijack DNS。
{
  inputs,
  lib,
  mylib,
  pkgs,
  config,
  ...
}:
let
  # 完整复用 client-config.nix（与 nixos 轨同一份代理正确性逻辑）。
  # 路径：modules/sm/mihomo.nix → 上 2 层到仓库根 → lib/mihomo/client-config.nix
  client = import ../../lib/mihomo/client-config.nix {
    inherit config mylib lib pkgs;
    selfProviderTemplateName = "mihomo-self-provider.yaml";
  };
in
{
  _file = ./mihomo.nix;

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
  # 注意：WorkingDirectory=/var/lib/mihomo 需要目录先存在，否则 ExecStartPre 都 CHDIR 失败。
  # 用 tmpfiles 建目录（sm 支持 systemd.tmpfiles），unit 只建 providers 子目录。
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
      # 注意：systemd Environment 是 key=value 对，多个用多个 entry（不能用空格串）。
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
