# sm-vps-hk：共享 VPS（他人也在用）。
# 基线能力在 group base；shared=true 关闭会影响他人的全局副作用。
{
  ...
}:
{
  imports = [ ../default.nix ];

  modules.sm.shared = true;

  # 共享机不管理用户，避免重写 /etc/passwd 影响他人 root 登录。
  services.userborn.enable = false;
}
