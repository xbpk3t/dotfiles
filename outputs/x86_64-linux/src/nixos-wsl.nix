{
  inputs,
  mylib,
  lib,
  mkSpecialArgs,
  ...
}@args:
let
  name = "nixos-wsl";
  node = mylib.inventory."nixos-wsl".${name};

  modules = {
    system = "x86_64-linux";
    inherit lib;
    nixos-modules = [
      inputs.sops-nix.nixosModules.sops
      # NixOS-WSL：systemd、/etc/wsl.conf、Windows interop 都由它接管。
      inputs.nixos-wsl.nixosModules.default
    ]
    ++ map mylib.relativeToRoot [
      # hosts/nixos-wsl 只 import ../_base/nixos-wsl；公共模块在 base 里。
      "hosts/${name}/default.nix"
      "secrets/default.nix"
    ];
    # 这版只验证 fleet 的系统配置在 WSL 下 rebuild，不挂 home-manager。
    # 需要 HM 时再加 home-modules（先最小 HM，再考虑 home/core）。
  };

  systemArgs =
    modules
    // args
    // {
      specialArgs = mkSpecialArgs modules.system node;
    };
  nixosConfig = mylib.nixosSystem systemArgs;
in
{
  nixosConfigurations.${name} = nixosConfig;
}
