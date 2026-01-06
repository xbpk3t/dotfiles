{
  inputs,
  lib,
  mylib,
  myvars,
  ...
} @ args: let
  name = "nixos-vps";
  tags = [name "vps"];
  ssh-user = "root";
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
        "modules/nixos/base"
        "modules/nixos/vps/dokploy-server"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "home/base/core"
    ];
  };

  targets = [
    {
      host = "103.85.224.63";
      user = ssh-user;
      tags = tags;
    }
    {
      host = "142.171.154.61";
      user = ssh-user;
      tags = tags;
    }
  ];

  role = mylib.mkColmenaRole {
    inherit lib mylib modules args name targets;
    genSpecialArgs = vpsSpecialArgs;
    system = "x86_64-linux";
    baseTags = tags;
  };
in {
  inherit (role) nixosConfigurations colmena;
}
