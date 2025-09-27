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

    # anyrun - a wayland launcher
    anyrun = {
      url = "github:anyrun-org/anyrun/v25.9.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # catppuccin theme
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
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

    # haumea for module loading
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  outputs = inputs: import ./outputs inputs;
}
