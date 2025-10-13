{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, etc.
  inputs,
  mylib,
  myvars,
  lib,
  ...
} @ args: let
  nixosSystemArgs = args // {inherit lib;};

  name = "nixos-ws";

  genSpecialArgs = system: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.nvidia.acceptLicense = true;
    };
  in {
    inherit
      inputs
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

    # Add DankMaterialShell packages
    # DMS requires dmsCli and dgop from its own inputs
    dmsPkgs = {
      dankMaterialShell = inputs.dankMaterialShell.packages.${system}.default;
      dmsCli = inputs.dankMaterialShell.inputs.dms-cli.packages.${system}.default;
      dgop = inputs.dankMaterialShell.inputs.dgop.packages.${system}.dgop;
    };
  };

  modules = {
    nixos-modules =
      (map mylib.relativeToRoot [
        # Host-specific configuration
        "hosts/${name}/default.nix"
        # common
        "secrets/default.nix"
        "modules/base"
        "modules/nixos/base"
        "modules/nixos/desktop"
      ])
      ++ [
        inputs.sops-nix.nixosModules.sops
        inputs.noctalia.nixosModules.default
        {
          modules.desktop.wayland.enable = true;
        }
      ];
    home-modules =
      (map mylib.relativeToRoot [
        # Host-specific home configuration
        "hosts/${name}/home.nix"
        "home/base"
        "home/nixos"
      ])
      ++ [
        inputs.noctalia.homeModules.default
        inputs.dankMaterialShell.homeModules.dankMaterialShell.default
        inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
        inputs.niri.homeModules.niri
      ];
  };
in {
  nixosConfigurations.${name} = mylib.nixosSystem (nixosSystemArgs
    // modules
    // {
      genSpecialArgs = genSpecialArgs;
      system = "x86_64-linux";
    });
}
