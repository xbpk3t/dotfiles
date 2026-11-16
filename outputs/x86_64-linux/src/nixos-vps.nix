{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  ...
}@args:
let
  # inventory 节点名 → hosts 目录名；dev 继续使用 hosts/nixos-vps。
  name = "nixos-vps-dev";
  hostDir = "nixos-vps";
  node = mylib.inventory."nixos-vps".${name} or null;

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
      # server 是 curated cockpit：不整包 import home/base。
      "home/base/devops/rclone.nix"
      "home/base/devops/ghui.nix"
      "home/base/devops/hunk.nix"
      "home/base/devops/herdr-core.nix"
      "home/base/devops/yazi.nix"
      "home/base/langs/lsp.nix"
      "home/base/devops/helix.nix"
      "home/base/AI/claude.nix"
      "home/base/AI/skills.nix"
      "home/base/AI/dagu.nix"
    ];
  };

  systemArgs =
    modules
    // args
    // {
      specialArgs = mkSpecialArgs modules.system node;
    };
  nixosConfig = mylib.nixosSystem systemArgs;
  deployNode = mylib.inventory.deployRsNode {
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
