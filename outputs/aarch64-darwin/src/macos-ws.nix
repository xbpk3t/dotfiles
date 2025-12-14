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
        # Host-specific configuration
        "hosts/${name}/home.nix"
        "secrets/home.nix"
        "modules/darwin"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/home.nix"
      # Host-specific home configuration
      "hosts/${name}/home.nix"
      "home/base/core"
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
