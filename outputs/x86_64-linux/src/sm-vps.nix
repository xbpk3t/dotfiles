{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  ...
}@args:
let
  group = "sm-vps";
  system = "x86_64-linux";
  nodes = mylib.fleet.groups.${group};

  # 为组内每个节点生成一套出口：
  #   homeConfigurations.<name> — standalone HM（组合由 node home.nix 决定）
  #   systemConfigs.<name>      — system-manager（node default imports group base）
  #   deploy.nodes.<name>       — deploy-rs 双 profile（system=sm / home=HM）
  # 同一文件产出全部节点，靠 outputs/default.nix 的 mergeRoleOutputList 合并。
  mkNode =
    name: node:
    let
      # sm-vps-tc -> tc；sm-vps-hk -> hk
      leaf = lib.removePrefix "${group}-" name;
      hostDir = "${group}/${leaf}";
      specialArgs = mkSpecialArgs system node;

      # 组合由节点自己决定：
      #   tc -> ../home.nix + home/core + secrets
      #   hk -> ../home.nix + curated no-sops home/core subset
      homeConfig = mylib.homeStandalone (
        args
        // {
          inherit system specialArgs;
          home-modules = map mylib.relativeToRoot [
            "hosts/${hostDir}/home.nix"
          ];
        }
      );

      # system-manager：node default 自己 import group base + modules/sm；
      # outputs 只补 platform glue。
      systemConfig = mylib.systemManager {
        inherit inputs;
        specialArgs = {
          inherit (specialArgs)
            inputs
            mylib
            hostMeta
            userMeta
            timeMeta
            pkgs
            ;
          inherit lib;
        };
        system-modules = [
          (mylib.relativeToRoot "hosts/${hostDir}/default.nix")
          {
            nixpkgs.hostPlatform = system;
            # 允许在 Debian 等非白名单 distro 上 eval/后续 switch（Phase 4）
            system-manager.allowAnyDistro = lib.mkDefault true;
          }
        ];
      };

      # Phase 5：deploy-rs 双 profile 节点（system=sm / home=HM）。
      deployNode = mylib.fleet.deploySmHmNode {
        inherit name node;
        systemToplevel = systemConfig.config.build.toplevel;
        # homeConfigurations 值本身带顶层 activationPackage（deploy-rs activate.home-manager 期望）。
        homeActivationPackage = homeConfig;
        deployLib = inputs."deploy-rs".lib.${system};
        # 默认 remoteBuild = true（目标机构建，Mac 零闭包下载）。这里不显式传，用构造器默认。
      };
    in
    {
      homeConfigurations.${name} = homeConfig;
      systemConfigs.${name} = systemConfig;
      deploy.nodes.${name} = deployNode;
    };

  # 组内所有节点的出口合并为一个 role 文件结果。
  outputs = builtins.foldl' (
    acc: name:
    let
      nodeOutputs = mkNode name nodes.${name};
    in
    {
      homeConfigurations = (acc.homeConfigurations or { }) // nodeOutputs.homeConfigurations;
      systemConfigs = (acc.systemConfigs or { }) // nodeOutputs.systemConfigs;
      deploy = {
        nodes = (acc.deploy.nodes or { }) // nodeOutputs.deploy.nodes;
      };
    }
  ) { } (builtins.attrNames nodes);
in
outputs
