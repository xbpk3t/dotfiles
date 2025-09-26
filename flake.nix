{
  description = "NixOS for Me";

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

    # nvf for neovim configuration
    nvf = {
      url = "github:notashelf/nvf";
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

    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=latest";
  };

  outputs = inputs @ {
    darwin,
    nixpkgs,
    home-manager,
    nix-homebrew,
    nix-flatpak,
    sops-nix,
    stylix,
    ...
  }: let
    # Create mylib utility functions
    mylib = import ./lib/default.nix {lib = nixpkgs.lib;};

    username = "luck";
    mail = "yyzw@live.com";
    hostname = "MacBook-Pro";

    # Special args for Darwin configurations
    darwinSpecialArgs = {
      inherit username mail hostname inputs;
      inherit sops-nix;
      inherit stylix;
      inherit mylib;
    };

    # Special args for NixOS configurations
    nixosSpecialArgs = {
      inherit inputs mylib sops-nix;
      username = "luck";
      host = "default";
      profile = "nvidia-laptop";
      mail = "yyzw@live.com";
    };
    # Special args for both Darwin and NixOS configurations that need nvf
  in {
    # Darwin configurations
    darwinConfigurations = {
      "macos-ws" = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = darwinSpecialArgs;
        modules = [
          ./modules/darwin
          stylix.darwinModules.stylix
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
            home-manager = (import ./home/darwin) darwinSpecialArgs;
          }
          sops-nix.darwinModules.sops
          ./hosts/darwine
          ./secrets/default.nix
        ];
      };
    };

    # NixOS configurations
    nixosConfigurations = {
      "nixos-ws" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = nixosSpecialArgs;
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            home-manager = (import ./home/nixos) nixosSpecialArgs;
          }
          ./hosts/nixos/default
          # nixvim.nixDarwinModules.nixvim
        ];
      };

      "nixos-gs" = {};
      "nixos-homelab" = {};

      # FIXME 之后处理
      #  "nixos-cli" = nixpkgs.lib.nixosSystem {
      #    system = linuxSystem;
      #    specialArgs = linuxSpecialArgs;
      #    modules = [
      #      # Host-specific configuration
      #      ./hosts/nixos
      #      # home manager for NixOS
      #      home-manager.nixosModules.home-manager
      #      {
      #        home-manager = {
      #          useGlobalPkgs = true;
      #          useUserPackages = true;
      #          extraSpecialArgs = linuxSpecialArgs;
      #          backupFileExtension = "hm-bak";
      #          users.${username} = import ./home;
      #        };
      #      }
      #
      #      sops-nix.nixosModules.sops
      #    ];
      #  };
    };
  };
}
