{
  hostMeta,
  lib,
  mylib,
  ...
}:
let
  # 本机自己的硬件/链路参数，不再按 hostname 去 inventory 里反查。
  hw = hostMeta.hardware or null;
  sysctl = if hw == null then mylib.vpsSysctl.mkDefaultSysctl else mylib.vpsSysctl.mkSysctl hw;
in
{
  # VPS 专用：根据 hostMeta.hardware 动态生成 sysctl
  # mkForce 确保覆盖 nixpkgs 默认 sysctl（如 fs.inotify.max_user_instances），
  # 避免在容器等叠加上下文中出现 "defined multiple times" 错误。
  boot.kernel.sysctl = lib.mkForce sysctl;
}
