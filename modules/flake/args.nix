{ inputs, lib, ... }: let
  mylib = import ../../lib { inherit lib; };
  myvars = import ../../vars { inherit lib; };
  customPkgsOverlay = import ../../pkgs/overlay.nix;

  genSpecialArgs = system: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.nvidia.acceptLicense = true;
      config.allowBroken = true;
      overlays = [ customPkgsOverlay ];
    };
  in {
    inherit inputs mylib myvars pkgs;
    pkgs-unstable = import (inputs.nixpkgs-unstable or inputs.nixpkgs) {
      inherit system;
      config.allowUnfree = true;
      config.allowBroken = true;
      overlays = [ customPkgsOverlay ];
    };
  };
in {
  _module.args = {
    inherit inputs mylib myvars genSpecialArgs;
  };
}
