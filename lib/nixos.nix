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
  # NOTE:
  # nixos/lib/eval-config.nix 会在 specialArgs.pkgs 存在时直接给出 warning。
  # 正确做法是通过 nixosSystem 的 pkgs 参数传入，并从 specialArgs 中移除 pkgs。
  nixosSpecialArgs = builtins.removeAttrs specialArgs ["pkgs"];
in
  nixpkgs.lib.nixosSystem {
    inherit system;
    pkgs = specialArgs.pkgs;
    specialArgs = nixosSpecialArgs;
    modules =
      nixos-modules
      ++ [
        nixos-generators.nixosModules.all-formats
      ]
      ++ (lib.optionals ((lib.lists.length home-modules) > 0) [
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
              # what: 将 nix-index wrapper 和预生成 database 接入共享 Home Manager 主线。
              # why: 这样 Linux/Darwin 复用同一套配置，不需要在各平台重复接线。
              inputs.nix-index-database.homeModules.default
              inputs.nvf.homeManagerModules.default
              inputs.sops-nix.homeManagerModules.sops
            ];
        }
      ]);
  }
