# sm-vps-hk：共享 VPS（他人也在用）。
# 基线能力在 group base；shared=true 关闭会影响他人的全局副作用。
{
  ...
}:
{
  imports = [ ../default.nix ];

  # 共享机不管理用户（userborn 由 modules/sm 按 shared 关闭）。
  modules.sm.shared = true;
}
