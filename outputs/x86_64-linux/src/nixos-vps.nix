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
  roleName = "nixos-vps";
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
        "hosts/${roleName}/default.nix"
        "secrets/default.nix"
        "modules/nixos/base"
        "modules/nixos/vps"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "home/base/core"
    ];
  };

  # inventory（可变）：节点差异
  inventory = import (mylib.relativeToRoot "inventory/nixos-vps.nix");
  nodes = inventory.nodes;

  genSpecialArgs = system: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [customPkgsOverlay];
    };
  in {
    inherit inputs mylib myvars pkgs;

    pkgs-unstable = import inputs.nixpkgs-unstable or inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [customPkgsOverlay];
    };
  };

  mkNodeModule = name: node: {
    # 变更项都放到 inventory，避免散落在各个 hosts
    networking.hostName = node.hostName or name;

    modules.networking.tailscale.derper = {
      enable = true;
      domain = node.tailscale.derpDomain;
      acmeEmail = myvars.mail;
    };
  };

  mkNodeRole = name: node: let
    tags = [name "vps"] ++ (node.tags or []);
    nodeModule = mkNodeModule name node;
    modules =
      baseModules
      // {
        nixos-modules = baseModules.nixos-modules ++ [nodeModule];
      };
    systemArgs = modules // args;
  in {
    nixosConfigurations.${name} = mylib.nixosSystem (systemArgs
      // {
        inherit genSpecialArgs;
      });

    colmena.${name} = mylib.colmenaSystem (systemArgs
      // {
        inherit genSpecialArgs tags;
        targetHost = node.targetHost;
        targetPort = node.targetPort or null;
        targetUser = node.user or ssh-user;
        ssh-user = node.user or ssh-user;
        extraModules = [nodeModule];
      });
  };

  nodeRoles = builtins.attrValues (builtins.mapAttrs mkNodeRole nodes);

  merged = {
    nixosConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.nixosConfigurations or {}) nodeRoles
    );
    colmena = lib.attrsets.mergeAttrsList (map (it: it.colmena or {}) nodeRoles);
  };
in
  merged
