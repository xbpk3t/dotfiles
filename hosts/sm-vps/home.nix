# sm-vps 角色：用户态声明（standalone HM）。
# 与 nixos 轨 hosts/<role>/home.nix 对齐——home/core 由 sm-vps.nix 统一 import，
# 这里声明角色特有的用户态开关（复用 home/base 的精选模块）。
{
  modules = {
    # 用户态开关（对齐 nixos home.nix 的 modules.*.enable 语义）
    # 需要哪些 home/base 模块，在这里点选（像 nixos-vps 的 home.nix 一样）。
  };
}
