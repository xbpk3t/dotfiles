# Darwin-specific modules
{ ... }:

{
  imports = [
    ./system-limits.nix
    ./directories.nix
    ./users.nix
    ./system.nix
    ./homebrew.nix
    # Package definitions
    ./pkg
  ];
}
