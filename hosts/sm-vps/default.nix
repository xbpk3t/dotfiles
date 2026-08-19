# sm-vps 角色：非 NixOS 系统态声明（sm 轨的「装配清单」）。
# 与 nixos 轨 hosts/<role>/default.nix 对齐——但 sm 是非 NixOS，无 NixOS module
# 语义，这里声明 sm 轨的角色配置。
#
# 关键：基础能力（sops/sshd/systemd/i18n/tailscale）是 sm-vps 的必要基线，
# 由 modules/sm 直接 enable（不配置化）。这里只声明「服务角色」：
#   modules.networking.mihomo.enable      — 代理客户端（可选，默认 false）
#   modules.infra.singbox-server.enable   — 代理服务端（sm-vps 默认不做，长期机才做）
#   modules.infra.derper.enable           — DERP 中继（SGP）
#   modules.infra.status-page.enable      — 状态页（SGP fleet）
# 对齐 nixos-vps/default.nix 的 modules.infra.singbox-server.enable / mihomo-server.enable。
{
  lib,
  isShared ? false,
  ...
}:
{
  # 服务角色（对齐 nixos-vps/default.nix 的 server/client 区分）：
  # sm-vps-tc 在 SGP（新加坡），公网直通，不需要代理客户端出网。
  # mihomo 此前为试验性开启；client-config.nix 的 allow-lan + bind-address="*"
  # 会在直连公网的 VPS 上形成无认证开放代理暴露面（对抗式审查 S1），故禁用
  # （默认 false，见 modules/sm/mihomo.nix）。
  # 共享机（shared=true）是他人共用的 VPS，不跑代理服务端/中继/状态页：
  #   - modules 全部常驻 import（option 存在），shared 下配置主体由各模块内
  #     lib.mkIf (!isShared) 门控（依赖 sops/tailscale 的部分不求值）。
  #   - 这里只在 shared 下显式关闭 userborn（重写 /etc/passwd 影响他人 root 登录）。
  modules.infra.singbox-server.enable = lib.mkIf (!isShared) true;
  modules.infra.derper.enable = lib.mkIf (!isShared) true;
  modules.infra.status-page.enable = lib.mkIf (!isShared) true;

  # 共享机（shared=true）：userborn 会重写 /etc/passwd 并把 root shell 指向 store bash，
  # 影响他人 root 登录体验；关闭（shared 下不管理用户）。
  services.userborn.enable = lib.mkIf isShared false;
}