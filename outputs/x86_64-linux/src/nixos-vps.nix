{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  ...
}@args:
let
  name = "nixos-vps";
  ssh-user = "root";

  # 单一 host role：server/agent 的差异由 hosts/nixos-vps/default.nix 和
  # hosts/nixos-vps/home.nix 按 hostMeta.role 声明，不在 output 里分两套模块。
  baseModules = {
    system = "x86_64-linux";
    inherit lib;
    nixos-modules = [
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
    ]
    ++ map mylib.relativeToRoot [
      "hosts/${name}/default.nix"
      "secrets/default.nix"
      "modules/nixos/kernel"
      "modules/nixos/infra/nix-tools.nix"
      "modules/nixos/infra/singbox-server.nix"
      "modules/nixos/infra/tailscale-client.nix"
      "modules/nixos/infra/mihomo-client.nix"
      "modules/nixos/ms/k3s.nix"
    ];
    home-modules = map mylib.relativeToRoot [
      "hosts/${name}/home.nix"
      "secrets/default.nix"
      "home/core"
    ];
  };

  # inventory（可变）：节点差异
  inventory = mylib.inventory."nixos-vps";
  nodes = inventory;

  # 只注入 inventory identity；role 差异由 host 层读取 hostMeta.role 处理。
  mkNodeModule = name: node: {
    networking.hostName = node.hostName or name;
  };

  mkNodeRole =
    name: node:
    let
      nodeModule = mkNodeModule name node;
      modules = baseModules // {
        nixos-modules = baseModules.nixos-modules ++ [ nodeModule ];
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
merged
