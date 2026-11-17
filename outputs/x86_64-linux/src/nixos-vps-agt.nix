{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  ...
}@args:
let
  name = "nixos-vps-agt";
  hostDir = "nixos-vps-agt";
  node = mylib.fleet.nodes.${name} or null;

  modules = {
    system = "x86_64-linux";
    inherit lib;
    nixos-modules = [
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
    ]
    ++ map mylib.relativeToRoot [
      "hosts/${hostDir}/default.nix"
      "secrets/default.nix"
      "modules/nixos/kernel"
      "modules/nixos/infra"
    ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "hosts/${hostDir}/home.nix"
      "home/core"
      "home/base"
      "home/nixos"
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
