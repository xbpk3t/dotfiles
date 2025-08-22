{ username, lib, pkgs, ... }:

{
  # Only configure users for Darwin systems
  # NixOS systems have their own user configuration in modules/nixos/users.nix
  users.users.${username} = lib.mkIf pkgs.stdenv.isDarwin {
    home = "/Users/${username}";
    description = username;
  };

  nix.settings.trusted-users = [ username ];
}
