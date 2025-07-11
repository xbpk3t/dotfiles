{ pkgs, lib, ... }:

{
  # Disable nix-darwin's management of the Nix installation for Determinate compatibility
  nix.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Note: Nix settings, garbage collection, and optimization are managed by Determinate Nix
  # For manual garbage collection, use: nix-collect-garbage --delete-older-than 7d
  # For store optimization, use: nix store optimise

  # Set Git commit hash for darwin-version.
  system.configurationRevision = lib.mkIf (builtins.pathExists ./.git) (lib.mkDefault "dirty");
}
