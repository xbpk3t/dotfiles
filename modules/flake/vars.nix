{ inputs, lib, config, ... }:
let
  self = inputs.self;
  mylib = import (self + /lib) { inherit lib; };
  myvars = import (self + /vars) { inherit lib; };
  baseCommon = {
    flake = {
      inherit self inputs config;
      lib = inputs.nixpkgs.lib;
    };
    inherit inputs mylib myvars;
  };
in {
  flake.nixos-unified.lib.specialArgsFor = {
    common = baseCommon;
    nixos = baseCommon;
    darwin = baseCommon // {
      rosettaPkgs = import inputs.nixpkgs { system = "x86_64-darwin"; };
    };
  };
}
