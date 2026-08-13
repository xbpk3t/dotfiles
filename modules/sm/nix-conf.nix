# sm 轨 Nix 守护/配置收敛（S1 骨架，S2 填充）。
# 上游自带 nix.settings（NixOS 模块适配），可直接声明 nix.settings.*。
# 目标：把 Determinate 安装时的 /etc/nix/nix.conf 声明化，防止手改漂移。
{ ... }:
{
  _file = ./nix-conf.nix;

  # S2 TODO：声明 nix.settings（experimental-features、trusted-users、substituters 等）。
  # nix.settings = {
  #   experimental-features = [ "nix-command" "flakes" ];
  #   trusted-users = [ "root" "@wheel" ];
  # };
}
