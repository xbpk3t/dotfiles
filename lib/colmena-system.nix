# Helper to build colmena node entries that share the same modules/home-modules
# as nixosConfigurations.
# lib/colmena-system.nix 仍在用：lib/mkColmenaRole.nix 内部为每个 target 生成节点时，最终调用的就是 mylib.colmenaSystem 来拼出 deployment + NixOS/Home Manager imports，所以它是“底层构造器”；mkColmenaRole 只是把多主机扇出、命名、tags 封装了一层。换言之，链路是：角色文件 → mkColmenaRole →colmenaSystem。所以 colmena-system.nix 还在发挥作用，不是闲置。
{
  lib,
  inputs,
  system,
  genSpecialArgs,
  nixos-modules,
  home-modules ? [],
  myvars,
  targetHost,
  targetUser,
  targetPort ? null,
  tags ? [],
  extraModules ? [],
  specialArgs ? (genSpecialArgs system),
  ...
}: let
  inherit (inputs) home-manager nvf sops-nix;
  deploymentBase =
    {
      inherit tags targetHost targetUser;
    }
    // lib.optionalAttrs (targetPort != null) {inherit targetPort;};
  homeManagerModules = lib.optionals (home-modules != []) [
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      # home-manager.backupFileExtension = "hm.bk";
      home-manager.backupFileExtension = null;

      home-manager.extraSpecialArgs = specialArgs;
      home-manager.users."${myvars.username}".imports =
        home-modules
        ++ [
          nvf.homeManagerModules.default
          sops-nix.homeManagerModules.sops
        ];
    }
  ];
in {
  deployment = deploymentBase;
  imports = nixos-modules ++ extraModules ++ homeManagerModules;
}
