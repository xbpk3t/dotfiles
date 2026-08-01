{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  ...
}@args:
let
  name = "linux-sm-lab";
  group = "linux-sm";
  system = "x86_64-linux";
  node = mylib.inventory.${group}.${name};
  specialArgs = mkSpecialArgs system node;

  # standalone HM：仅 home/core 最小；sops 由 homeStandalone 挂模块（eval 需要）。
  # secrets/default.nix 提供 sops.secrets.* 定义，否则 home/core 引用 path 会失败。
  homeModules = map mylib.relativeToRoot [
    "home/core"
    "secrets/default.nix"
  ];

  homeConfig = mylib.homeStandalone (
    args
    // {
      inherit system specialArgs;
      home-modules = homeModules;
      backupFileExtension = "hm.bak";
    }
  );

  # system-manager：platform + 极简占位；不 import modules/nixos/**
  systemConfig = mylib.systemManager {
    inherit inputs;
    specialArgs = {
      inherit (specialArgs)
        inputs
        mylib
        hostMeta
        userMeta
        ;
      inherit lib;
    };
    system-modules = [
      (mylib.relativeToRoot "modules/system")
      {
        nixpkgs.hostPlatform = system;
        # 允许在 Debian 等非白名单 distro 上 eval/后续 switch（Phase 4）
        system-manager.allowAnyDistro = lib.mkDefault true;
      }
    ];
  };
in
{
  homeConfigurations.${name} = homeConfig;
  systemConfigs.${name} = systemConfig;
}
