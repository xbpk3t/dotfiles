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
      "modules/nixos/infra"
      "modules/nixos/ms/k3s.nix"
    ];
    home-modules = map mylib.relativeToRoot [
      "hosts/${name}/home.nix"
      "secrets/default.nix"
      "home/core"
    ];
  };

  # inventory（可变）：节点差异；role 由 host 层读取 hostMeta.role 处理。
  inventory = mylib.inventory."nixos-vps";

  mkNodeRole =
    name: node:
    let
      systemArgs =
        baseModules
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
        # 4G agent 上跑全量 nix build 容易 OOM；agent 改为本地（Mac/remote builder）
        # 构建后 copy closure，server 节点保持 remoteBuild=true。
        remoteBuild = (node.role or "server") != "agent";
      };
    in
    {
      nixosConfigurations.${name} = nixosConfig;
      deploy.nodes.${name} = deployNode;
    };

  nodeRoles = builtins.attrValues (builtins.mapAttrs mkNodeRole inventory);

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
