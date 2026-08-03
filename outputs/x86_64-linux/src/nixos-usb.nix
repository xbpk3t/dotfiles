{
  inputs,
  mylib,
  lib,
  mkSpecialArgs,
  ...
}@args:
let
  name = "nixos-usb";
  node = mylib.inventory."nixos-usb".${name};

  modules = {
    system = "x86_64-linux";
    # 说明：显式透传 lib，避免 deadnix 误删后导致下游 nixosSystem 缺参。
    inherit lib;
    nixos-modules = [
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
    ]
    ++ map mylib.relativeToRoot [
      # Host-specific configuration
      "hosts/${name}/default.nix"
      "hosts/${name}/disko.nix"
      # common
      "secrets/default.nix"
      "modules/nixos/kernel"
      "modules/nixos/desktop"
      "modules/nixos/infra/nix-tools.nix"
      "modules/nixos/infra/tailscale-client.nix"
      "modules/nixos/infra/singbox-client.nix"
    ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      # Host-specific home configuration
      "hosts/${name}/home.nix"
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
  deployNode = mylib.inventory.deployRsNode {
    inherit name node;
    nixosConfiguration = nixosConfig;
    deployLib = inputs."deploy-rs".lib."x86_64-linux";
    defaultSshUser = "root";
    # U 盘系统不远程构建：在构建机（VPS/Mac）构建，推 closure 到 U 盘
    # Why: 插到公司/未知机器上，目标机构建环境不可控
    remoteBuild = false;
  };
in
{
  nixosConfigurations.${name} = nixosConfig;
  deploy.nodes.${name} = deployNode;
  packages =
    let
      isoName = "${name}-iso";
    in
    {
      ${isoName} = nixosConfig.config.system.build.isoImage;
    };
}
