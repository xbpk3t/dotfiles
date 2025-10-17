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
            # Darwin 系统使用 nixpkgs-darwin，配置 allowBroken = true
            nixpkgs.config.allowUnfree = true;
            nixpkgs.config.allowBroken = true; # 允许安装 broken 包（如 zig）
          }
        )
      ]
      ++ (lib.optionals ((lib.lists.length home-modules) > 0) [
        home-manager.darwinModules.home-manager
        # mac-app-util - Fix .app programs installed by Nix on Mac
        inputs.mac-app-util.darwinModules.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "home-manager.backup";

          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users."${myvars.username}".imports =
            home-modules
            ++ [
              inputs.nixvim.homeModules.nixvim
              inputs.nvf.homeManagerModules.default
              # mac-app-util home-manager module
              inputs.mac-app-util.homeManagerModules.default
            ];
        }
      ]);
  }
