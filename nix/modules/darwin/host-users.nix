{...}: {
  # Shared host user configuration patterns for Darwin systems
  # Note: NixOS systems have their own user configuration in modules/nixos/users.nix

  users.users = {};

  # Shared Nix settings
  nix.settings = {
    # Shared trusted users configuration
    # Note: Host-specific trusted users should be configured per-host
    # trusted-users = [ ];
  };
}
