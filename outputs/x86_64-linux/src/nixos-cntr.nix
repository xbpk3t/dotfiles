{
  inputs,
  lib,
  mylib,
  myvars,
  ...
} @ args: let
  nixosSystemArgs = args // {inherit lib;};
  name = "nixos-cntr";
  customPkgsOverlay = import (mylib.relativeToRoot "pkgs/overlay.nix");
  cntrSpecialArgs = system: let
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
    #    nixos-modules =
    #      [
    #        inputs.sops-nix.nixosModules.sops
    #        inputs.disko.nixosModules.disko
    #      ]
    #      ++ map mylib.relativeToRoot [
    #        "hosts/${name}/default.nix"
    #        "modules/base"
    #        "modules/nixos/base"
    #        "modules/nixos/vps"
    #      ];
    #    home-modules = map mylib.relativeToRoot [
    #      "secrets/default.nix"
    #      "home/base/core"
    #      "home/nixos/base"
    #    ];

    nixos-modules =
      [
        inputs.sops-nix.nixosModules.sops
      ]
      ++ map mylib.relativeToRoot [
        "hosts/${name}/default.nix"
        "secrets/default.nix"
        "modules/nixos/base/ssh.nix"
        "modules/nixos/base/shell.nix"
        "modules/nixos/base/user-group.nix"
        "modules/nixos/extra/singbox"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "home/base/core"
    ];
  };
in {
  nixosConfigurations.${name} = mylib.nixosSystem (nixosSystemArgs
    // modules
    // {
      genSpecialArgs = cntrSpecialArgs;
    });

  colmenaProfiles.${name} = {
    inherit (modules) system nixos-modules home-modules;
    genSpecialArgs = cntrSpecialArgs;
    defaultTargetUser = "root";
  };
}
