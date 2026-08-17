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
  nodes = mylib.inventory.${group};

  # 为组内每个节点生成一套出口：
  #   homeConfigurations.<name> — standalone HM（home/core + secrets）
  #   systemConfigs.<name>      — system-manager（modules/sm 薄模块）
  #   deploy.nodes.<name>       — deploy-rs 双 profile（system=sm / home=HM）
  # 同一文件产出全部节点，靠 outputs/default.nix 的 mergeRoleOutputList 合并。
  mkNode =
    name: node:
    let
      specialArgs = mkSpecialArgs system node;

      # 共享机（shared = true）：HM 裁剪集 + 系统 sops 白名单空。
      # 与 dedicated 的差异见 hosts/sm-vps/default.nix 注释与 modules/sm/sops.nix。
      isShared = node.shared or false;

      # standalone HM：home/core 最小 + 角色 home.nix（对齐 nixos 轨 hosts/<role>/home.nix）。
      # secrets/default.nix 提供 sops.secrets.* 定义，否则 home/core 引用 path 会失败。
      homeModules = map mylib.relativeToRoot (
        if isShared then
          [
            "hosts/${group}/home-shared.nix"
            # 裁剪集：不 import home/core（其 scanPaths 会带进 zsh/gh/cntr → sops）
            # 显式 import 无 sops 引用的模块
            "home/core/init.nix"
            "home/core/infra/nh.nix"
            "home/core/infra/networking.nix"
            "home/core/kernel/fzf.nix"
            "home/core/devops/git.nix"
            "home/core/devops/btop.nix"
            "home/core/devops/fastfetch.nix"
            "home/core/devops/lazygit.nix"
            "home/core/devops/journalctl.nix"
            "home/core/devops/taskfile.nix"
            "home/core/db/default.nix"
            "home/core/ms/default.nix"
          ]
        else
          [
            "hosts/${group}/home.nix"
            "home/core"
            "secrets/default.nix"
          ]
      );

      homeConfig = mylib.homeStandalone (
        args
        // {
          inherit system specialArgs;
          home-modules = homeModules;
          backupFileExtension = "hm.bak";
        }
      );

      # system-manager：platform + 极简占位；不 import modules/nixos/**
      # 共享机额外传 isShared，供 modules/sm 按 shared 分支裁剪（见 default.nix）。
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
          inherit
            lib
            isShared
            ;
        };
        system-modules = [
          # 角色装配清单（hosts/<role>/default.nix：声明服务角色，如 services.mihomo-client.enable）
          (mylib.relativeToRoot "hosts/${group}/default.nix")
          # sm 模块树（基线能力直接 enable；服务角色读 services.*.enable）
          (mylib.relativeToRoot "modules/sm")
          {
            nixpkgs.hostPlatform = system;
            # 允许在 Debian 等非白名单 distro 上 eval/后续 switch（Phase 4）
            system-manager.allowAnyDistro = lib.mkDefault true;
          }
        ];
      };

      # Phase 5：deploy-rs 双 profile 节点（system=sm / home=HM）。
      deployNode = mylib.inventory.deploySmHmNode {
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
