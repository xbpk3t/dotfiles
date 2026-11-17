# sm-vps group HM base。
#
# 共享机不能 import home/core（scanPaths 会带进 zsh/gh/cntr → sops 引用），
# 所以这里只放两个节点都有的、无 sops 副作用的配置。
# 具体组合由 tc/hk 的 home.nix 决定。
{
  ...
}:
{
  # 两个节点都 import 了 home/core/infra/nh.nix（tc 全量 core，hk curated）。
  modules.infra.nh.enable = true;
}
