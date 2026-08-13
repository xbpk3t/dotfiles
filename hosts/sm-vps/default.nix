# sm-vps 角色：非 NixOS 系统态声明（sm 轨的「装配清单」）。
# 与 nixos 轨 hosts/<role>/default.nix 对齐——但 sm 是非 NixOS，无 NixOS module
# 语义，这里声明 sm 轨的角色配置。
#
# 关键：基础能力（sops/sshd/systemd/i18n/tailscale）是 sm-vps 的必要基线，
# 由 modules/sm 直接 enable（不配置化）。这里只声明「服务角色」：
#   services.mihomo-client.enable   — 代理客户端（可选）
#   services.singbox-server.enable  — 代理服务端（sm-vps 默认不做，长期机才做）
# 对齐 nixos-vps/default.nix 的 services.singbox-server.enable / mihomo-server.enable。
{
  # 服务角色（对齐 nixos-vps/default.nix 的 server/client 区分）：
  # sm-vps 做代理客户端（出网），不做 server（server 是长期机职责，singbox-server
  # 属 D3 未实现，sm 轨暂不声明）。
  services.mihomo-client.enable = true;

  # 基础能力由 modules/sm 直接 enable（无开关）：
  #   sops（secrets 注入）、sshd 硬化、systemd（journald/logind）、i18n、tailscale。
  # 不需要在这里声明——modules/sm 无条件启用它们。
}
