{lib, ...}: let
  mylib = import ../../../../lib {inherit lib;};
  inventory = import ../../../../inventory/nixos-vps.nix;
  hw = inventory.nodes."nixos-vps-dev".hardware;
in {
  format = "json";
  expr = mylib.nettune.mkSysctl hw;
}
