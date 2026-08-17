# sm-vps 共享机（shared=true）用户态声明。
# 与 home.nix（dedicated）的差异：
#   - 不 import home/core 全量（scanPaths 会带进 zsh/gh/cntr → 引用 sops secrets）
#   - 只启用无 sops 引用的模块（见 outputs/.../sm-vps.nix 的 isShared 分支）
#   - 不挂 sops：共享机上不放主 age key，无需 secrets 解密
{
  modules = {
    # Nix 工具（与 home.nix 对齐；无 sops 依赖）
    infra.nh.enable = true;
    infra.networking.enable = true;
  };
}
