# Turn one fleet node into all flake outputs it owns.
#
# 输入只依赖 node（hosts/**/meta.nix + path）和平台构造器；
# 具体模块组合由 hosts/<group>/<node>/{default,home}.nix 自己 import。
{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  genSpecialArgs,
}:
{ name, node }:
let
  system = node.system;
  specialArgs = mkSpecialArgs system node;
  deployLib = inputs."deploy-rs".lib.${system};

  hostDefault = node.path + "/default.nix";
  hostHome = node.path + "/home.nix";
  hasHome = builtins.pathExists hostHome;
  homeModules = lib.optional hasHome hostHome;

  mkNixosConfig = mylib.nixosSystem {
    inherit
      inputs
      lib
      system
      genSpecialArgs
      specialArgs
      ;
    nixos-modules = [ hostDefault ];
    home-modules = homeModules;
  };

  mkDarwinConfig = mylib.macosSystem {
    inherit
      inputs
      lib
      system
      genSpecialArgs
      specialArgs
      ;
    darwin-modules = [ hostDefault ];
    home-modules = homeModules;
  };

  mkSmHome = mylib.homeStandalone {
    inherit
      inputs
      system
      genSpecialArgs
      specialArgs
      ;
    home-modules = homeModules;
  };

  mkSmSystem = mylib.systemManager {
    inherit inputs;
    # 多传的 specialArgs 对未声明它们的模块是惰性的；不再手维护白名单，
    # 避免 sm 轨新增 specialArg 时被静默漏掉。
    specialArgs = specialArgs // {
      inherit lib;
    };
    system-modules = [
      hostDefault
      {
        nixpkgs.hostPlatform = system;
        system-manager.allowAnyDistro = lib.mkDefault true;
      }
    ];
  };

  mkNixosDeploy =
    config:
    mylib.fleet.deployRsNode {
      inherit name node deployLib;
      nixosConfiguration = config;
      remoteBuild = node.deploy.remoteBuild or true;
    };

  mkDarwinDeploy =
    config:
    (mylib.fleet.deployTarget {
      inherit name node;
      defaultSshUser = "luck";
      remoteBuild = node.deploy.remoteBuild or true;
    })
    // {
      magicRollback = node.deploy.magicRollback or false;
      profiles.system = {
        user = "root";
        path = deployLib.activate.custom config.system "./activate";
      };
    };

  mkSmDeploy =
    systemConfig: homeConfig:
    mylib.fleet.deploySmHmNode {
      inherit name node deployLib;
      systemToplevel = systemConfig.config.build.toplevel;
      homeActivationPackage = homeConfig;
      remoteBuild = node.deploy.remoteBuild or true;
    };
in
if node.kind == "nixos" then
  {
    nixosConfigurations.${name} = mkNixosConfig;
  }
  // lib.optionalAttrs (node ? deploy) {
    deploy.nodes.${name} = mkNixosDeploy mkNixosConfig;
  }
else if node.kind == "darwin" then
  {
    darwinConfigurations.${name} = mkDarwinConfig;
  }
  // lib.optionalAttrs (node ? deploy) {
    deploy.nodes.${name} = mkDarwinDeploy mkDarwinConfig;
  }
else if node.kind == "sm" then
  {
    homeConfigurations.${name} = mkSmHome;
    systemConfigs.${name} = mkSmSystem;
  }
  // lib.optionalAttrs (node ? deploy) {
    deploy.nodes.${name} = mkSmDeploy mkSmSystem mkSmHome;
  }
else
  throw "mkHost: unsupported kind '${node.kind}' for node '${name}'"
