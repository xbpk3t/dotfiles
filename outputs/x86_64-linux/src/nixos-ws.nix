{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, etc.
  inputs,
  mylib,
  myvars,
  lib,
  ...
} @ args: let
  name = "nixos-ws";
  ssh-user = myvars.username;
  ssh-host = "192.168.234.194";

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
    system = "x86_64-linux";
    # 说明：显式透传 lib，避免 deadnix 误删后导致下游 nixosSystem 缺参。
    inherit lib;
    nixos-modules =
      [inputs.sops-nix.nixosModules.sops]
      ++ map mylib.relativeToRoot [
        # Host-specific configuration
        "hosts/${name}/default.nix"
        "modules/nixos/hardware/nvidia.nix"

        # common
        "secrets/default.nix"
        "modules/nixos/base"
        "modules/nixos/desktop"
        "modules/nixos/extra/singbox-client.nix"
        "modules/nixos/extra/vscode-remote.nix"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      # Host-specific home configuration
      "hosts/${name}/home.nix"
      "home/base"
      "home/nixos"
    ];
  };
  systemArgs = modules // args;
  nixosConfig = mylib.nixosSystem (systemArgs
    // {
      inherit genSpecialArgs;
    });
  deployNode = mylib.inventory.deployRsNode {
    inherit name;
    node = {
      primaryIp = ssh-host;
      ssh = {
        user = ssh-user;
      };
    };
    nixosConfiguration = nixosConfig;
    deployLib = inputs."deploy-rs".lib."x86_64-linux";
    defaultSshUser = ssh-user;
    remoteBuild = false;
  };
in {
  nixosConfigurations.${name} = nixosConfig;
  deploy.nodes.${name} = deployNode;
}
