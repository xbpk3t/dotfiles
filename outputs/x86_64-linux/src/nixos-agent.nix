{
  inputs,
  mylib,
  lib,
  mkSpecialArgs,
  ...
} @ args: let
  name = "nixos-agent";
  node = mylib.inventory."nixos-agent".${name};

  modules = {
    system = "x86_64-linux";
    inherit lib;
    nixos-modules =
      [inputs.sops-nix.nixosModules.sops]
      ++ map mylib.relativeToRoot [
        "hosts/${name}/default.nix"
        "modules/nixos/base"
        "secrets/default.nix"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "hosts/${name}/home.nix"
      "home/core"
      "home/base/AI"
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
in {
  nixosConfigurations.${name} = nixosConfig;
  deploy.nodes.${name} = deployNode;
}
