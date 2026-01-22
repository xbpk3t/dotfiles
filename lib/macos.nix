{
  lib,
  inputs,
  darwin-modules,
  home-modules ? [],
  myvars,
  system,
  genSpecialArgs,
  specialArgs ? (genSpecialArgs system),
  ...
}: let
  inherit (inputs) home-manager darwin;
in
  darwin.lib.darwinSystem {
    inherit system specialArgs;
    modules =
      darwin-modules
      ++ [
        (
          {...}: {
            # what: 让系统与 Home Manager 复用同一个预配置 pkgs 实例。
            # why: 使用 home-manager.useGlobalPkgs 时，设置 nixpkgs.config/overlays 会触发警告；
            #      通过 nixpkgs.pkgs 复用 specialArgs.pkgs 可避免该问题并保持一致性。
            nixpkgs.pkgs = specialArgs.pkgs;
          }
        )
      ]
      ++ (lib.optionals ((lib.lists.length home-modules) > 0) [
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # home-manager.backupFileExtension = "hm.bk";
          home-manager.backupFileExtension = null;

          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users."${myvars.username}".imports =
            home-modules
            ++ [
              inputs.nvf.homeManagerModules.default
              inputs.sops-nix.homeManagerModules.sops
            ];
        }
      ]);
  }
