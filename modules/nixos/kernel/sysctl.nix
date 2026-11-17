{
  config,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.kernel.sysctl;
  sysctl =
    if cfg.hardware == null then
      mylib.vpsSysctl.mkDefaultSysctl
    else
      mylib.vpsSysctl.mkSysctl cfg.hardware;
in
{
  options.modules.kernel.sysctl = {
    hardware = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      description = ''
        VPS hardware/network profile used to derive kernel sysctl.
        Set this in the host module; leave null to use the default tuning.
      '';
    };
  };

  # 模块里已有 `options`，其它配置必须放进显式 `config`。
  config = {
    # VPS 专用：根据 host module 提供的 hardware profile 动态生成 sysctl。
    # mkForce 确保覆盖 nixpkgs 默认 sysctl（如 fs.inotify.max_user_instances），
    # 避免在容器等叠加上下文中出现 "defined multiple times" 错误。
    boot.kernel.sysctl = lib.mkForce sysctl;
  };
}
