{
  inputs,
  mylib,
  lib,
  mkSpecialArgs,
  ...
}@args:
let
  name = "nixos-ws";
  node = mylib.inventory."nixos-ws".${name};

  modules = {
    system = "x86_64-linux";
    # 说明：显式透传 lib，避免 deadnix 误删后导致下游 nixosSystem 缺参。
    inherit lib;
    nixos-modules = [
      inputs.sops-nix.nixosModules.sops
    ]
    ++ map mylib.relativeToRoot [
      # Host-specific configuration
      "hosts/${name}/default.nix"
      # common
      "secrets/default.nix"
      "modules/nixos/kernel"
      "modules/nixos/desktop/nvidia.nix"
      "modules/nixos/desktop"
      "modules/nixos/infra/nix-tools.nix"
      "modules/nixos/infra/singbox-client.nix"
      "modules/nixos/infra/mihomo-client.nix"
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
    remoteBuild = true;
  };
in
{
  nixosConfigurations.${name} = nixosConfig;
  deploy.nodes.${name} = deployNode;
}
