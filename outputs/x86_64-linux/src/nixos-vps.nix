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
    nixos-modules = map mylib.relativeToRoot [
      "hosts/${name}/default.nix"
      "modules/base"
      "modules/nixos/base"
      "modules/nixos/vps"
    ];
    home-modules = map mylib.relativeToRoot [
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
}
