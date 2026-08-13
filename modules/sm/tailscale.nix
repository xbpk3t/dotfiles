# sm 轨 tailscale 声明。
# 上游 system-manager 无 services.tailscale 模块（未适配 NixOS 的 tailscale）。
# 现状（Phase 8 已验证）：tailscale 由 bootstrap 官方 install script 安装，
# tailscaled unit 由官方脚本管理（/etc/systemd/system/tailscaled.service），
# 登录态在 /var/lib/tailscale。sm 若再声明 systemd unit 会撞 unmanaged path。
# 结论：tailscale 系统服务归官方脚本，不进 sm 声明（符合「系统层尽量薄」哲学）。
#
# 该模块只提供 enable 开关（标记「该角色用 tailscale」），无实际 config——
# 系统服务本身由 bootstrap 官方脚本管理。
{ lib, ... }:
{
  _file = ./tailscale.nix;

  options.modules.sm.tailscale.enable = lib.mkEnableOption "tailscale（官方脚本管理，sm 不接管）";

  # 预留：若未来要 sm 接管，需先处理 tailscaled.service 的 unmanaged 冲突，
  # 或改用 sm 的 environment.etc + systemd.services 完整声明。
}
