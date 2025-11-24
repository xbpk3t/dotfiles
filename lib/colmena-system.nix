# Helper to build colmena node entries that share the same modules/home-modules
# as nixosConfigurations.
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
      home-manager.backupFileExtension = "home-manager.backup";
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
