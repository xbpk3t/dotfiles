{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, etc.
  inputs,
  lib,
  mylib,
  myvars,
  ...
} @ args: let
  name = "nixos-vps";
  ssh-user = "root";
  customPkgsOverlay = import (mylib.relativeToRoot "pkgs/overlay.nix");

  # 角色（不变）：infra 基线
  baseModules = {
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
        "modules/nixos/vps"
        "modules/nixos/extra/k3s.nix"
      ];
    home-modules = map mylib.relativeToRoot [
      "hosts/${name}/home.nix"
      "secrets/default.nix"
      "home/base/core"
      "home/extra/zed-remote.nix"
    ];
  };

  # inventory（可变）：节点差异
  inventory = mylib.inventory."nixos-vps";
  nodes = inventory;

  genSpecialArgs = system: let
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

  mkNodeModule = name: node:
    {
      # 变更项都放到 inventory，避免散落在各个 hosts
      networking.hostName = node.hostName or name;

      modules.networking.tailscale.derper = {
        enable = true;
        domain = node.tailscale.derpDomain;
        acmeEmail = myvars.mail;
      };
    }
    // lib.optionalAttrs (node ? k3s) {
      modules.extra.k3s = node.k3s;
    };

  mkNodeRole = name: node: let
    nodeModule = mkNodeModule name node;
    modules =
      baseModules
      // {
        nixos-modules = baseModules.nixos-modules ++ [nodeModule];
      };
    systemArgs = modules // args;
    nixosConfig = mylib.nixosSystem (
      systemArgs
      // {
        inherit genSpecialArgs;
      }
    );
    deployNode = mylib.inventory.deployRsNode {
      inherit name node;
      nixosConfiguration = nixosConfig;
      deployLib = inputs."deploy-rs".lib.${baseModules.system};
      defaultSshUser = ssh-user;
      remoteBuild = true;
    };
  in {
    nixosConfigurations.${name} = nixosConfig;
    deploy.nodes.${name} = deployNode;
  };

  nodeRoles = builtins.attrValues (builtins.mapAttrs mkNodeRole nodes);

  merged = {
    nixosConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.nixosConfigurations or {}) nodeRoles
    );
    deploy = {
      nodes = lib.attrsets.mergeAttrsList (map (it: it.deploy.nodes or {}) nodeRoles);
    };
  };
in
  merged
