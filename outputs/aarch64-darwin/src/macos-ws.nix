{
  inputs,
  mylib,
  myvars,
  lib,
  ...
} @ args: let
  macosSystemArgs = args // {inherit lib;};

  name = "macos-ws";

  genSpecialArgs = system: let
    customPkgsOverlay = import (mylib.relativeToRoot "pkgs/overlay.nix");
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.nvidia.acceptLicense = true;
      overlays = [
        customPkgsOverlay
      ];
    };
  in {
    inherit
      inputs
      mylib
      myvars
      pkgs
      ;

    # use unstable branch for some packages to get the latest updates
    pkgs-unstable = import inputs.nixpkgs-unstable or inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        customPkgsOverlay
      ];
    };
  };

  modules = {
    darwin-modules =
      [inputs.sops-nix.darwinModules.sops]
      ++ map mylib.relativeToRoot [
        "secrets/default.nix"
        "modules/darwin"
        "hosts/${name}/default.nix"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "hosts/${name}/home.nix"
      "home/base"
      "home/darwin"
    ];
  };
in {
  darwinConfigurations.${name} = mylib.macosSystem (macosSystemArgs
    // modules
    // {
      genSpecialArgs = genSpecialArgs;
      system = "aarch64-darwin";
    });
}
