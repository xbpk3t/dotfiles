_:

{
  # Disable nix-darwin's management of the Nix installation for Determinate compatibility
  nix.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Note: Nix settings, garbage collection, and optimization are managed by Determinate Nix
  # For manual garbage collection, use: nix-collect-garbage --delete-older-than 7d
}
