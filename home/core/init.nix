# Home-Manager 配置的最小可运行底盘。
#
# 为什么放在 `home/core/` 而不是 `home/base/`：
#   - `home/core/` 的语义是「每个 host 都必须有的最小基线」，
#     从 c41e3f9 拆出 core / base 后，所有 host 的 home-modules 都
#     包含 `home/core`，没有任何 host 会绕过它。
#   - `home/base/` 的语义是「富配置（GUI / CLI 工具的可选项）」，
#     headless 的 nixos-vps 已经显式 *不* import `home/base`，
#     因此任何 home-manager 必备的 option 都不能挂在 `home/base/` 里，
#     否则该 host 求值时会因为缺少 `home.username` / `home.homeDirectory`
#     / `home.stateVersion` 而直接 fail（在 home-manager assertions 阶段）。
#
# 它设置的四件事都属于「不设置就无法生成 generation」的硬性要求：
#   1. `home.username` —— home-manager 用它定位用户目录与 activation target
#   2. `home.homeDirectory` —— `mkForce` 是为了覆盖 home-manager 基于
#      `getEnv "HOME"` 的默认推断，在 cross-system / pure eval 场景下后者
#      可能为空或指向 builder 临时目录，必须显式钉死
#   3. `home.stateVersion` —— state migration 锚点，`mkDefault` 允许 host
#      在升级时按需 override；这里固定 24.11 是首次落地版本
#   4. `programs.home-manager.enable` —— 让 home-manager 自管自身，否则
#      `home-manager switch` 这类 CLI 在用户 profile 里就拿不到
{
  pkgs,
  lib,
  userMeta,
  stateVersion,
  ...
}:
let
  username = userMeta.username;
in
{
  home = {
    inherit username;
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}"
    );
    stateVersion = lib.mkDefault stateVersion;
  };

  programs.home-manager.enable = true;
}
