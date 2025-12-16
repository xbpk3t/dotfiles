{ flake, myvars, ... }:
let
  inherit (flake) inputs;
  self = inputs.self;
  mylib = import (self + /lib) { inherit (inputs.nixpkgs) lib; };
  myvars = import (self + /vars) { inherit (inputs.nixpkgs) lib; };
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    (self + /secrets/default.nix)
    (self + /modules/nixos/base)
    (self + /hosts/nixos-vps/default.nix)
    (self + /hosts/nixos-vps/modules.nix)
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
