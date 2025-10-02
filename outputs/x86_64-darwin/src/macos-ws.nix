{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.macosSystem`, etc.
  inputs,
  mylib,
  myvars,
  lib,
  ...
} @ args: let
  name = "macos-ws";

  # Darwin system modules
  darwin-modules =
    (map mylib.relativeToRoot [
      # common
      "secrets/default.nix"
      # Darwin specific modules
      "modules/darwin"
    ])
    ++ [
      inputs.stylix.darwinModules.stylix
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.sops-nix.darwinModules.sops
      {
        nix-homebrew = {
          enable = true;
          enableRosetta = false;
          user = myvars.username;
          autoMigrate = true;
        };
      }
    ];

  # Home Manager modules
  home-modules = map mylib.relativeToRoot [
    "home/darwin"
    "home/base"
  ];

  # System args combining all modules
  systemArgs =
    args
    // {
      inherit darwin-modules home-modules lib;
      system = "x86_64-darwin";
    };
in {
  darwinConfigurations.${name} = mylib.macosSystem systemArgs;
}
