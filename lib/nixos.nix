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
    # NOTE: We pass pkgs through specialArgs, which causes evaluation warnings about
    # nixpkgs.config and nixpkgs.overlays being ignored. This is intentional and expected.
    # The pkgs instance is already configured in genSpecialArgs (outputs/default.nix) with
    # allowUnfree, allowBroken, and nvidia.acceptLicense settings.
    # These warnings can be safely ignored as they don't affect functionality.
    modules =
      nixos-modules
      ++ [
        nixos-generators.nixosModules.all-formats
        inputs.stylix.nixosModules.stylix
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
              inputs.nixvim.homeModules.nixvim
              inputs.nvf.homeManagerModules.default
              # inputs.vicinae.homeManagerModules.default
            ];
        }
      ]);
  }
