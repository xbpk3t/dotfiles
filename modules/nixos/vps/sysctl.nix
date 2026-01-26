{
  config,
  lib,
  mylib,
  ...
}: let
  inventory = mylib.inventory."nixos-vps";
  hostName = lib.attrByPath ["networking" "hostName"] null config;
  node =
    if hostName == null
    then null
    else inventory.${hostName} or null;
  hw =
    if node == null
    then null
    else node.hardware or null;
  sysctl =
    if hw == null
    then mylib.vpsSysctl.mkDefaultSysctl
    else mylib.vpsSysctl.mkSysctl hw;
in {
  # VPS 专用：根据 inventory.hardware 动态生成 sysctl
  boot.kernel.sysctl = sysctl;
}
