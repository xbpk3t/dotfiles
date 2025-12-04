{
  inputs,
  lib,
  mylib,
  myvars,
  ...
} @ args: let
  nixosSystemArgs = args // {inherit lib;};
  name = "nixos-vps";
  customPkgsOverlay = import (mylib.relativeToRoot "pkgs/overlay.nix");
  vpsSpecialArgs = system: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [customPkgsOverlay];
    };
  in {
    inherit
      inputs
      mylib
      myvars
      pkgs
      ;

    pkgs-unstable = import inputs.nixpkgs-unstable or inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [customPkgsOverlay];
    };
  };
  modules = {
    system = "x86_64-linux";
    inherit lib myvars;
    nixos-modules =
      [
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
      ]
      ++ map mylib.relativeToRoot [
        "hosts/${name}/default.nix"
        "secrets/default.nix"
        "modules/base"
        "modules/nixos/base"
        "modules/nixos/vps"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "home/base/core"
      "home/nixos/base"
    ];
  };
in {
  nixosConfigurations.${name} = mylib.nixosSystem (nixosSystemArgs
    // modules
    // {
      genSpecialArgs = vpsSpecialArgs;
    });

  colmenaProfiles.${name} = {
    inherit (modules) system nixos-modules home-modules;
    genSpecialArgs = vpsSpecialArgs;
    defaultTargetUser = "root";
  };
}
