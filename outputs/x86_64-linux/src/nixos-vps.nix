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
        "modules/nixos/cntr/nixos-agent.nix"
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
    hostName = node.hostName or name;
    nodeModule = mkNodeModule name node;
    agentNodes = mylib.inventory.nodesForContainerHost "nixos-agent" hostName;
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

    # 从当前 VPS node 拥有的 agent inventory nodes 生成容器 deploy nodes。
    # Why: 容器系统配置已经在宿主 nixosConfig.containers.<name>.config 中求值，
    #      这里复用该结果并从宿主 inventory 自动派生 SSH ProxyJump。
    containerDeployLib = inputs."deploy-rs".lib.${baseModules.system};
    containerDeploy = let
      hostAddress = mylib.inventory.primaryHostForNode name node;
      mkContainerDeploy = agentName: agentNode: let
        containerConfig = nixosConfig.config.containers.${agentName} or null;
        ssh = agentNode.ssh or {};
        deployAgentNode =
          agentNode
          // {
            ssh =
              ssh
              // {
                opts = (ssh.opts or []) ++ ["-J" "${ssh-user}@${hostAddress}"];
              };
          };
      in
        if containerConfig != null
        then {
          ${agentName} = mylib.inventory.deployRsNode {
            name = agentName;
            node = deployAgentNode;
            # containerConfig.config 是容器子模块求值后的 raw merged config（有 .system.build.toplevel），
            # 而非 evalModules 结果（有 .config.system.build.toplevel）。
            # deployLib.activate.nixos 期望后者，所以用 { config = ...; } 包裹一层。
            nixosConfiguration = {config = containerConfig.config;};
            deployLib = containerDeployLib;
            defaultSshUser = "root";
            remoteBuild = true;
          };
        }
        else {};
    in
      lib.attrsets.mergeAttrsList (lib.mapAttrsToList mkContainerDeploy agentNodes);
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
