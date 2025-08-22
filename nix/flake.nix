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

    # stylix for system-wide theming
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs-darwin,
    darwin,
    home-manager,
    nix-homebrew,
    nixvim,
    nixhelm,
    stylix,
    ...
  }: let
    # User configuration
    username = let envUser = builtins.getEnv "USER"; in
      if envUser != "" then envUser else "lhgtqb7bll";
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

    # Darwin-specific modules (keeping existing structure for now)
    darwinModules = [
      ./modules/nix-core.nix
      ./modules/system.nix
      ./modules/homebrew.nix
      ./modules/host-users.nix
      ./modules/stylix.nix
      ./pkg
      ./modules/shared
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

          # stylix for system-wide theming
          stylix.darwinModules.stylix

          # home manager
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = darwinSpecialArgs;
            # 添加备份文件扩展名设置
            home-manager.backupFileExtension = "hm-bak";
            home-manager.users.${username} = import ./home;
          }
        ];
      };
    };

    # TODO: NixOS configurations will be added after Darwin migration is complete

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
