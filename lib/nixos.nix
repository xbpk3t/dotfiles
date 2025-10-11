{
  inputs,
  lib,
  system,
  genSpecialArgs,
  nixos-modules,
  home-modules ? [],
  specialArgs ? (genSpecialArgs system),
  myvars,
  ...
}: let
  inherit (inputs) nixpkgs home-manager nixos-generators;
in
  nixpkgs.lib.nixosSystem {
    inherit system specialArgs;
    modules =
      nixos-modules
      ++ [
        nixos-generators.nixosModules.all-formats
        inputs.stylix.nixosModules.stylix
        (
          {...}: {
            # NixOS 系统使用 nixpkgs，配置 allowBroken = true
            nixpkgs.config.allowBroken = true; # 允许安装 broken 包（如 zig）
          }
        )
      ]
      ++ (lib.optionals ((lib.lists.length home-modules) > 0) [
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm.bk";

          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users."${myvars.username}".imports =
            home-modules
            ++ [
              inputs.catppuccin.homeModules.catppuccin
              inputs.nixvim.homeModules.nixvim
              inputs.nvf.homeManagerModules.default
              # inputs.vicinae.homeManagerModules.default
            ];
        }
      ]);
  }
