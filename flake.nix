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
    myvars,
    ...
  }: let
    inherit (myvars) username;
    inherit (myvars) mail;
    hostname = "MacBook-Pro";

    specialArgs = {
      inherit username mail hostname inputs;
      inherit sops-nix;
      inherit stylix;
    };
  in {
    # Darwin configurations
    darwinConfigurations = {
      "macos-ws" = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        inherit specialArgs;
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
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              backupFileExtension = "hm-bak";
              users.${username} = import ./home;
            };
          }
          sops-nix.darwinModules.sops
          ./hosts/darwin
          ./secrets/darwin.nix
        ];
      };
    };

    # NixOS configurations
    nixosConfigurations = {
      "nixos-ws" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          username = "luck";
          host = "default";
          profile = "amd-hybrid";
        };
        modules = [
          ./modules/nixos/profiles/amd-hybrid
          nix-flatpak.nixosModules.nix-flatpak
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
