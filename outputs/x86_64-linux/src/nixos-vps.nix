{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  ...
}@args:
let
  # fleet 节点名 → group/node 目录。
  name = "nixos-vps-dev";
  hostDir = "nixos-vps/dev";
  node = mylib.fleet.nodes.${name} or null;

  modules = {
    system = "x86_64-linux";
    inherit lib;
    # 平台 glue、capability 树、secrets 和 HM 组合都由 group base / node
    # 自己 import；outputs 只负责把节点入口接进来。
    nixos-modules = map mylib.relativeToRoot [
      "hosts/${hostDir}/default.nix"
    ];
    home-modules = map mylib.relativeToRoot [
      "hosts/${hostDir}/home.nix"
    ];
  };

  systemArgs =
    modules
    // args
    // {
      specialArgs = mkSpecialArgs modules.system node;
    };
  nixosConfig = mylib.nixosSystem systemArgs;
  deployNode = mylib.fleet.deployRsNode {
    inherit name node;
    nixosConfiguration = nixosConfig;
    deployLib = inputs."deploy-rs".lib.${modules.system};
    defaultSshUser = "root";
    # 所有节点本地构建：不配置远程 builder，dev 不再 self-build，
    # agt 也不再依赖 dev；agent 用 max-jobs=1/cores=1 控制内存。
    remoteBuild = true;
  };
in
lib.optionalAttrs (node != null) {
  nixosConfigurations.${name} = nixosConfig;
  deploy.nodes.${name} = deployNode;
}
