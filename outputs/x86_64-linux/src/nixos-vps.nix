#{
#  lib,
#  mylib,
#  myvars,
#  genSpecialArgs,
#  ...
#} @ args: let
#  name = "nixos-vps";
#
#  modules = {
#    system = "x86_64-linux";
#    inherit genSpecialArgs myvars lib;
#    nixos-modules = map mylib.relativeToRoot [
#      # Host-specific configuration
#      "hosts/${name}/default.nix"
#      "modules/nixos/base"
#    ];
#    home-modules = [];
#  };
#in {
#  nixosConfigurations.${name} = mylib.nixosSystem (modules // args);
#}
{}
