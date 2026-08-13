# sm 轨 Nix 守护/配置收敛。
# 上游自带 nix.settings（NixOS 模块适配，见 nix/modules/upstream/nixpkgs/nix.nix）。
# 把实验特性与 trusted-users 声明化，防止手改漂移。
#
# ⚠️ 双源头：与 hosts/sm-vps/ansible/bootstrap.yml 的 2c（Determinate --extra-conf）
# 管理同一文件 /etc/nix/nix.conf。这里是稳态接管（sm switch 后覆写），
# Ansible 是安装时写入。trusted-users 语义要一致（本文件用 @sudo，2c 用 root luck）。
# 改任一侧要同步另一侧，否则 last-writer-wins 漂移。
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
    # 组名用 @sudo（Debian/Ubuntu 默认管理组）；RHEL 系用 @wheel。
    # 若目标机是 RHEL/CentOS，把这里改成 "@wheel" 或按 distro 参数化。
    trusted-users = [
      "root"
      "@sudo"
      "luck"
    ];
  };
}
