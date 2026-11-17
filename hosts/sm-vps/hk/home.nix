# sm-vps-hk：共享 VPS 用户态声明（standalone HM）。
#
# 与 tc 的差异：
#   - 不 import home/core 全量（scanPaths 会带进 zsh/gh/cntr → 引用 sops secrets）
#   - 显式 import 无 sops 引用的 home/core 子集
#   - 不挂 sops：共享机上不放主 age key，无需 secrets 解密
{ mylib, ... }:
{
  imports = [
    ../home.nix
  ]
  ++ map mylib.relativeToRoot [
    "home/core/init.nix"
    "home/core/infra/nh.nix"
    "home/core/infra/networking.nix"
    "home/core/kernel/fzf.nix"
    "home/core/devops/git.nix"
    "home/core/devops/btop.nix"
    "home/core/devops/fastfetch.nix"
    "home/core/devops/lazygit.nix"
    "home/core/devops/journalctl.nix"
    "home/core/devops/taskfile.nix"
    "home/core/db/default.nix"
    "home/core/ms/default.nix"
  ];

  modules.infra.networking.enable = true;
}
