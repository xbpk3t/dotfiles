# Nix 自身配置——sm 不接管（Determinate Nix 负责）。
#
# 对抗式调查结论（2026-08）：
# - Determinate Nix 用双文件：/etc/nix/nix.conf（Determinate 生成管理，
#   "do not modify! this file will be replaced!"） + /etc/nix/nix.custom.conf（被 include）。
# - 用户 Nix 配置应写 nix.custom.conf（Determinate 安装时 --extra-conf 即写这里）。
# - sm 上游的 nix module 若启用（nix.enable=true）会用 replaceExisting=true 覆写整个
#   nix.conf，抹掉 Determinate 的 flakehub cache / lazy-trees / netrc —— 冲突。
# - 且 sm 的 nix.enable 默认 false，我们未启用 → sm 的 nix.settings 从未生效。
#
# 因此：Nix 守护配置归 Determinate（bootstrap 的 --extra-conf 写 nix.custom.conf），
# sm 不声明 nix.settings，避免「声明了但不生效」或「覆写 Determinate」的坑。
_: {
  _file = ./nix-conf.nix;
}
