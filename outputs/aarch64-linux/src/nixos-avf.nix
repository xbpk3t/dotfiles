{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, etc.
  inputs,
  mylib,
  myvars,
  genSpecialArgs,
  lib,
  ...
} @ args: let
  name = "nixos-avf";

  modules = {
    system = "aarch64-linux";
    # 说明：显式透传 lib / myvars，避免后续 deadnix 或参数折叠后导致下游缺参。
    inherit lib myvars;
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
      inherit genSpecialArgs;
    }
  );
in {
  nixosConfigurations.${name} = nixosConfig;
}
