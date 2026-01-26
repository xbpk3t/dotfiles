{lib, ...}: let
  mylib = import ../../../../lib {inherit lib;};
  inventory = mylib.inventory.data;
  hw = inventory.nixos-vps."nixos-vps-dev".hardware;
in {
  format = "json";
  expr = mylib.vpsSysctl.mkSysctl hw;
}
