# sm 轨 tailscale 声明（S1 骨架，S2 填充）。
# 上游 system-manager 无 services.tailscale 适配（需自建 systemd unit 或走官方脚本）。
# 现状：tailscale 由 phase8-real.sh 官方脚本安装 + 一次性 up（登录态在 /var/lib/tailscale）。
# S2 TODO：评估是否声明 tailscaled unit（官方脚本已建 unit，sm 再声明会撞 unmanaged path）。
{ ... }:
{
  _file = ./tailscale.nix;

  # S2 讨论：tailscaled unit 由官方 install script 管理，sm 不宜重复声明。
  # 若要走 sm 声明，需先接管 /etc/systemd/system/tailscaled.service 的 unmanaged 冲突。
}
