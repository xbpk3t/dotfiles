{
  inputs,
  mylib,
  lib,
  mkSpecialArgs,
  ...
} @ args: let
  name = "nixos-avf";
  node = mylib.inventory."nixos-avf".${name};

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
      specialArgs = mkSpecialArgs modules.system node;
    }
  );
in {
  nixosConfigurations.${name} = nixosConfig;
}
