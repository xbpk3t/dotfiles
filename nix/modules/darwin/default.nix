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
    ./host-users.nix
    ./launchd.nix
    # Package definitions
    ./pkg
  ];
}
