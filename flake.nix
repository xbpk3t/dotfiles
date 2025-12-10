{
  description = "NixOS for Me";

  # nixConfig affects the flake itself, not the system configuration
  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://cache.garnix.io"
      "https://nix-community.cachix.org"
      "https://loneros.cachix.org"
      "https://numtide.cachix.org"
      "https://watersucks.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "watersucks.cachix.org-1:6gadPC5R8iLWQ3EUtfu3GFrVY7X6I4Fwz/ihW25Jbv8="
    ];

    # 防止关键包被垃圾回收清理
    keep-outputs = true;
    keep-derivations = true;
  };

  inputs = {
    # Use existing nixpkgs inputs
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # nixos-generators for creating ISO images
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Keep nix-homebrew for compatibility
    # https://github.com/zhaofengli/nix-homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    nvf.url = "github:notashelf/nvf";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Stylix theming system
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # haumea for module loading
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # namaka for snapshot testing
    namaka = {
      url = "github:nix-community/namaka/v0.2.1";
      inputs = {
        haumea.follows = "haumea";
        nixpkgs.follows = "nixpkgs";
      };
    };

    # https://github.com/numtide/flake-utils
    utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # https://github.com/numtide/nix-ai-tools
    nix-ai-tools.url = "github:numtide/nix-ai-tools";

    # https://github.com/natsukium/mcp-servers-nix
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://github.com/nix-community/NUR
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixos-cli - Modern NixOS management CLI
    # https://github.com/nix-community/nixos-cli
    nixos-cli = {
      url = "github:water-sucks/nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # mac-app-util - Fix .app programs installed by Nix on Mac
    # https://github.com/hraban/mac-app-util
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # colmena - NixOS deployment tool
    # https://github.com/zhaofengli/colmena
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: import ./outputs inputs;
}
