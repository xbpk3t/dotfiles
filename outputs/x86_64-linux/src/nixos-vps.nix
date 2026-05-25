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
      "home/core"
      "home/base/devops/rclone.nix"
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

    # 从 host nixosConfig 复用容器 eval 结果生成 deploy node。
    # Why: nixos-agent.nix 单独调 mylib.nixosSystem 会导致相同模块重复求值
    #      （host 求值已包含 containers.nixos-agent.config 的完整 eval）。
    #      这里直接复用 host eval 中已求值的容器 config，避免二次 eval。
    containerConfig = nixosConfig.config.containers.nixos-agent or null;
    containerDeployLib = inputs."deploy-rs".lib.${baseModules.system};
    containerDeploy =
      if containerConfig != null
      then let
        containerNode = mylib.inventory."nixos-agent"."nixos-agent" or null;
      in
        if containerNode != null
        then {
          "nixos-agent" = mylib.inventory.deployRsNode {
            name = "nixos-agent";
            node = containerNode;
            # containerConfig.config 是容器子模块求值后的 raw merged config（有 .system.build.toplevel），
            # 而非 evalModules 结果（有 .config.system.build.toplevel）。
            # deployLib.activate.nixos 期望后者，所以用 { config = ...; } 包裹一层。
            nixosConfiguration = {config = containerConfig.config;};
            deployLib = containerDeployLib;
            defaultSshUser = "root";
            remoteBuild = true;
          };
        }
        else {}
      else {};
  in {
    nixosConfigurations.${name} = nixosConfig;
    deploy.nodes =
      {
        ${name} = deployNode;
      }
      // containerDeploy;
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
