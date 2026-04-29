{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  ...
} @ args: let
  name = "nixos-vps";
  ssh-user = "root";

  # 角色（不变）：infra 基线
  baseModules = {
    system = "x86_64-linux";
    inherit lib;
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
        "modules/nixos/extra/k3s/default.nix"
      ];
    home-modules = map mylib.relativeToRoot [
      "hosts/${name}/home.nix"
      "secrets/default.nix"
      "home/base/core"
      "home/base/tui/works/pwn.nix"
      "home/extra/zed-remote.nix"
    ];
  };

  # inventory（可变）：节点差异
  inventory = mylib.inventory."nixos-vps";
  nodes = inventory;

  mkNodeModule = name: node:
    {
      # 变更项都放到 inventory，避免散落在各个 hosts
      networking.hostName = node.hostName or name;

      modules.networking.tailscale.derper = {
        enable = true;
        domain = node.tailscale.derpDomain;
        acmeEmail = node.acmeEmail;
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
    systemArgs =
      modules
      // args
      // {
        specialArgs = mkSpecialArgs baseModules.system node;
      };
    nixosConfig = mylib.nixosSystem systemArgs;
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
