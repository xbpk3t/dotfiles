# Darwin-specific modules
{ ... }:

{
  imports = [
    ./system-limits.nix
    ./directories.nix
    ./users.nix
    ./system.nix
    ./homebrew.nix
    ./nix-core.nix
    ./stylix.nix
    ./host-users.nix
    ./launchd.nix
    ./networking.nix
    # Package definitions
    ./pkg
  ];
}
