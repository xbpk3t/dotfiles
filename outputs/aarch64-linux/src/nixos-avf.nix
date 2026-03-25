{
  inputs,
  mylib,
  lib,
  mkSpecialArgs,
  ...
} @ args: let
  name = "nixos-avf";
  hostMeta = {
    hostName = name;
    user = {
      username = "luck";
      mail = "yyzw@live.com";
    };
    time = {
      timeZone = "Asia/Shanghai";
    };
  };

  modules = {
    system = "aarch64-linux";
    inherit lib;
    nixos-modules =
      [
        # 关键：导入 upstream 的 AVF module，system.build.avfImage 也由这里提供
        inputs.nixos-avf.nixosModules.avf
      ]
      ++ map mylib.relativeToRoot [
        "hosts/${name}/default.nix"
      ];
  };

  nixosConfig = mylib.nixosSystem (
    modules
    // args
    // {
      specialArgs = mkSpecialArgs modules.system hostMeta;
    }
  );
in {
  nixosConfigurations.${name} = nixosConfig;
}
