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
      # Query the mirror of USTC first, then official cache
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
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


  };

  outputs = inputs @ {
    nixpkgs-darwin,
    darwin,
    home-manager,
    nix-homebrew,
    ...
  }: let
    # User configuration
    username = let envUser = builtins.getEnv "USER"; in
      if envUser != "" then envUser else "luck";
    useremail = "yyzw@live.com";

    # System configurations
    darwinSystem = "x86_64-darwin"; # Intel Mac
    linuxSystem = "x86_64-linux";

    # Common special args for all configurations
    commonSpecialArgs = {
      inherit username useremail inputs;
    };

    # Darwin special args
    darwinSpecialArgs = commonSpecialArgs // {
      hostname = "MacBook-Pro";
      system = darwinSystem;
    };

    # Linux special args
    linuxSpecialArgs = commonSpecialArgs // {
      system = linuxSystem;
    };

    # Darwin-specific modules (updated structure)
    darwinModules = [
      ./modules/nix-core.nix
      ./modules/host-users.nix
      ./modules/darwin
    ];

    # NixOS-specific modules
    nixosModules = [
      ./modules/nix-core.nix
      # ./modules/host-users.nix  # Darwin-specific, not needed for NixOS
      ./modules/nixos
      ./modules/shared/packages.nix  # Add shared packages
      # ./modules/stylix.nix  # Temporarily disabled due to GitHub API limits
    ];

  in {
    # Darwin configurations
    darwinConfigurations = {
      # Local macOS machine
      "lHGtQdeMacBook-Pro-2" = darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = darwinSpecialArgs;
        modules = darwinModules ++ [
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
                extraSpecialArgs = darwinSpecialArgs;
                # 添加备份文件扩展名设置
                backupFileExtension = "hm-bak";
                users.${username} = import ./home;
            };
          }
        ];
      };
    };

    # NixOS configurations
    nixosConfigurations = {
      # Test NixOS system - minimal configuration
      "nixos" = nixpkgs-darwin.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = linuxSpecialArgs // {
          hostname = "nixos";
        };
        modules = [
          # Host-specific configuration
          ./hosts/nixos
          # home manager for NixOS
          home-manager.nixosModules.home-manager
          {
            home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = linuxSpecialArgs // {
                              hostname = "nixos";
                            };
                backupFileExtension = "hm-bak";
                users.${username} = import ./home;
            };
          }
        ];
      };
    };

    # Development shell
    devShells.${darwinSystem}.default = nixpkgs-darwin.legacyPackages.${darwinSystem}.mkShell {
      buildInputs = with nixpkgs-darwin.legacyPackages.${darwinSystem}; [
        home-manager
        # TODO: Add colmena and nixos-rebuild when NixOS support is added
      ];
    };

    # nix code formatter
    formatter.${darwinSystem} = nixpkgs-darwin.legacyPackages.${darwinSystem}.alejandra;
  };
}
