# sm 轨 Nix 守护/配置收敛。
# 上游自带 nix.settings（NixOS 模块适配，见 nix/modules/upstream/nixpkgs/nix.nix）。
# 与 phase2/8 安装 Determinate 时写入的 /etc/nix/nix.conf 对齐，
# 把实验特性与 trusted-users 声明化，防止手改漂移。
{ ... }:
{
  _file = ./nix-conf.nix;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # 与 Determinate installer 的 --extra-conf trusted-users 对齐。
    # luck 需要被信任，否则 sops/多用户操作受限。
    trusted-users = [
      "root"
      "@wheel"
      "luck"
    ];
  };
}
