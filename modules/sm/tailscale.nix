# sm 轨 tailscale 声明。
# 上游 system-manager 无 services.tailscale 模块（未适配 NixOS 的 tailscale）。
# 现状（Phase 8 已验证）：tailscale 由 phase8-real.sh 官方 install script 安装，
# tailscaled unit 由官方脚本管理（/etc/systemd/system/tailscaled.service），
# 登录态在 /var/lib/tailscale。sm 若再声明 systemd unit 会撞 unmanaged path。
# 结论：tailscale 系统服务归官方脚本，不进 sm 声明（符合「系统层尽量薄」哲学）。
{ ... }:
{
  _file = ./tailscale.nix;

  # 预留：若未来要 sm 接管，需先处理 tailscaled.service 的 unmanaged 冲突，
  # 或改用 sm 的 environment.etc + systemd.services 完整声明。
}
