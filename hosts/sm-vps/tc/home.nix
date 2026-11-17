# sm-vps-tc：dedicated VPS 用户态声明（standalone HM）。
#
# 组合在这里收口：
#   - group HM base（无 sops 副作用的公共项）
#   - home/core 全量
#   - secrets/default.nix（home/core 的 zsh/gh/cntr 引用 sops.secrets.*）
{ mylib, ... }:
{
  imports = [
    ../home.nix
    (mylib.relativeToRoot "home/core")
    (mylib.relativeToRoot "secrets/default.nix")
  ];
}
