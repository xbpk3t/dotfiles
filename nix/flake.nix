{
  description = "Multi-platform Nix configuration with Darwin and NixOS support";

  ##################################################################################################################
  #
  # Multi-host Nix configuration supporting both macOS (Darwin) and Linux (NixOS)
  # Migrated from Ansible-based infrastructure management
  #
  ##################################################################################################################

  # nixConfig affects the flake itself, not the system configuration
  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://cache.garnix.io"
      "https://nix-community.cachix.org"
      "https://loneros.cachix.org"
    ];

    # 防止关键包被垃圾回收清理
    keep-outputs = true;
    keep-derivations = true;
  };

  inputs = {
    # Use existing nixpkgs inputs
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Keep nix-homebrew for compatibility
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # nixvim for neovim configuration
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # nixhelm for helm charts management
    nixhelm = {
      url = "github:nix-community/nixhelm";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Stylix theming system
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  outputs = inputs @ {
    darwin,
    home-manager,
    nix-homebrew,
    sops-nix,
    stylix,
    ...
  }: let
    username = "lhgtqb7bll";
    mail = builtins.getEnv "MAIL";
    hostname = "MacBook-Pro";

    specialArgs = {
      inherit username mail hostname inputs;
      inherit sops-nix;
      inherit stylix;
    };
  in {
    # Darwin configurations
    darwinConfigurations = {
      # Local macOS machine
      "luck" = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        inherit specialArgs;
        modules = [
          ./modules/darwin
          # Stylix theming
          stylix.darwinModules.stylix
          # nix-homebrew integration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = username;
              autoMigrate = true;
            };
          }
          # home manager
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              backupFileExtension = "hm-bak";
              users.${username} = import ./home;
            };
          }
          sops-nix.darwinModules.sops
          # Import host-specific configuration
          ./hosts/darwin
          # Import secrets configuration
          ./secrets/darwin.nix
        ];
      };
    };
  };
}
