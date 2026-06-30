{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  ...
}@args:
let
  name = "nixos-homelab";
  ssh-user = "root";
  inventory = mylib.inventory."nixos-homelab";
  nodes = inventory;

  modules = {
    system = "x86_64-linux";
    inherit lib;
    nixos-modules = [
      inputs.sops-nix.nixosModules.sops
    ]
    ++ map mylib.relativeToRoot [
      "hosts/${name}/default.nix"
      "secrets/default.nix"
      "modules/nixos/kernel"
      "modules/nixos/infra/homelab.nix"

      "modules/nixos/devops/nvidia.nix"
      "modules/nixos/devops/fhs.nix"
      "modules/nixos/infra/singbox-client.nix"
      "modules/nixos/ms/k3s.nix"
    ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "hosts/${name}/home.nix"
      "home/core"
      "home/base"
      "home/nixos"
      "home/extra/jetbrains-remote.nix"
      "home/extra/zed-remote.nix"
    ];
  };

  mkNodeModule =
    name: node:
    {
      # What：hostName 由 inventory 注入。
      # Why：避免单机调试时为空，同时统一节点元数据入口。
      networking.hostName = node.hostName or name;
    }
    // lib.optionalAttrs (node ? k3s) {
      modules.extra.k3s = node.k3s;
    };

  mkNodeRole =
    name: node:
    let
      nodeModule = mkNodeModule name node;
      modulesWithNode = modules // {
        nixos-modules = modules.nixos-modules ++ [ nodeModule ];
      };
      systemArgs =
        modulesWithNode
        // args
        // {
          specialArgs = mkSpecialArgs modules.system node;
        };
      nixosConfig = mylib.nixosSystem systemArgs;
      deployNode = mylib.inventory.deployRsNode {
        inherit name node;
        nixosConfiguration = nixosConfig;
        deployLib = inputs."deploy-rs".lib."x86_64-linux";
        defaultSshUser = ssh-user;

        # [2026-01-25] 目前 dotfiles 在 mac 本地，所以 homelab 应开启 remoteBuild
        remoteBuild = true;
      };
    in
    {
      nixosConfigurations.${name} = nixosConfig;
      deploy.nodes.${name} = deployNode;
    };

  nodeRoles = builtins.attrValues (builtins.mapAttrs mkNodeRole nodes);

  merged = {
    nixosConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.nixosConfigurations or { }) nodeRoles
    );
    deploy = {
      nodes = lib.attrsets.mergeAttrsList (map (it: it.deploy.nodes or { }) nodeRoles);
    };
  };
in
{
  inherit (merged) nixosConfigurations;
  inherit (merged) deploy;
}
