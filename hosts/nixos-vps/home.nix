# Group HM base for all nixos-vps nodes.
#
# Node home.nix imports this and adds its role delta:
#   dev -> curated home/base cockpit
#   agt -> full home/base + home/nixos agent toolchain
{ mylib, ... }:
{
  imports = [
    (mylib.relativeToRoot "home/core")
    (mylib.relativeToRoot "secrets/default.nix")
  ];

  # 只放 group base 自己 import 的 home/core 能力。
  # devops/AI 的 option 定义在 home/base，由节点按自己的组合 import 并声明，
  # 否则只 import 本文件的节点会因 option 不存在而 eval 失败。
  modules.infra = {
    nh.enable = true;
    networking.enable = true;
  };
}
