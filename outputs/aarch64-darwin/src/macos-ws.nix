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
  systemArgs = macosSystemArgs // modules;
  darwinConfig = mylib.macosSystem (systemArgs
    // {
      genSpecialArgs = genSpecialArgs;
      system = "aarch64-darwin";
    });
  deployNode = let
    deployLib = inputs."deploy-rs".lib."aarch64-darwin";
    sshUser = myvars.username;
  in {
    hostname = name;
    inherit sshUser;
    remoteBuild = true;
    profiles.system = {
      user = "root";
      # nix-darwin exposes an activation script in the system closure
      path = deployLib.activate.custom darwinConfig.system "./activate";
    };
  };
in {
  darwinConfigurations.${name} = darwinConfig;
  deploy.nodes.${name} = deployNode;
}
