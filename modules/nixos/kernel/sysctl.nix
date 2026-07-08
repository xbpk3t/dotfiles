{
  config,
  lib,
  mylib,
  ...
}:
let
  inventory = mylib.inventory."nixos-vps";
  hostName = lib.attrByPath [ "networking" "hostName" ] null config;
  node = if hostName == null then null else inventory.${hostName} or null;
  hw = if node == null then null else node.hardware or null;
  sysctl = if hw == null then mylib.vpsSysctl.mkDefaultSysctl else mylib.vpsSysctl.mkSysctl hw;
in
{
  # VPS 专用：根据 inventory.hardware 动态生成 sysctl
  # mkForce 确保覆盖 nixpkgs 默认 sysctl（如 fs.inotify.max_user_instances），
  # 避免在容器等叠加上下文中出现 "defined multiple times" 错误。
  boot.kernel.sysctl = lib.mkForce sysctl;
}
