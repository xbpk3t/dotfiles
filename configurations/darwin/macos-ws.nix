{ flake, myvars, ... }:
let
  inherit (flake) inputs;
  self = inputs.self;
  mylib = import (self + /lib) { inherit (inputs.nixpkgs) lib; };
  myvars = import (self + /vars) { inherit (inputs.nixpkgs) lib; };
in {
  imports = [
    inputs.sops-nix.darwinModules.sops
    inputs.home-manager.darwinModules.home-manager
    (self + /secrets/default.nix)
    (self + /modules/darwin)
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "macos-ws";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = null;
    extraSpecialArgs = {
      inherit inputs mylib myvars;
    };
    users.${myvars.username}.imports = [
      (self + /secrets/default.nix)
      (self + /modules/home/base)
      (self + /modules/home/darwin)
    ];
  };
}
