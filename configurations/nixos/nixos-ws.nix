{ flake, myvars, ... }:
let
  inherit (flake) inputs;
  self = inputs.self;
  mylib = import (self + /lib) { inherit (inputs.nixpkgs) lib; };
  myvars = import (self + /vars) { inherit (inputs.nixpkgs) lib; };
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
    (self + /secrets/default.nix)
    (self + /modules/nixos/base)
    (self + /modules/nixos/desktop)
    (self + /hosts/nixos-ws/default.nix)
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
