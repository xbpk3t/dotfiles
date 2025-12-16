{ inputs, lib, system, ... }: let
  customPkgsOverlay = import ../../pkgs/overlay.nix;
in {
  # Provide pkgs for perSystem consumers (devShell, formatter, packages, etc.)
  _module.args.pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    config.allowBroken = true;
    config.nvidia.acceptLicense = true;
    overlays = [ customPkgsOverlay ];
  };
}
