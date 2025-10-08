{
  inputs,
  mylib,
  myvars,
  ...
} @ args: let
  name = "macos-ws";

  genSpecialArgs = system: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.nvidia.acceptLicense = true;
    };
  in {
    inherit
      mylib
      myvars
      pkgs
      ;

    # use unstable branch for some packages to get the latest updates
    pkgs-unstable = import inputs.nixpkgs-unstable or inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Add anyrun for anyrun configuration modules
    anyrun = inputs.anyrun;

    # Add catppuccin for theme configuration
    catppuccin = inputs.catppuccin;

    # Add nixvim for neovim configuration
    nixvim = inputs.nixvim;

    # Add vicinae for application launcher
    vicinae = inputs.vicinae;

    # Add sops-nix for secret management
    sops-nix = inputs.sops-nix;
  };

  modules = {
    darwin-modules =
      (map mylib.relativeToRoot [
        "secrets/default.nix"
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
    home-modules = map mylib.relativeToRoot [
      "home/darwin"
      "home/base"
    ];
  };
in {
  darwinConfigurations.${name} = mylib.macosSystem (args
    // modules
    // {
      genSpecialArgs = genSpecialArgs;
      system = "x86_64-darwin";
    });
}
