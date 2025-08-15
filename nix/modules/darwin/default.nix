# Darwin-specific modules
{ ... }:

{
  imports = [
    ./system-limits.nix
    ./directories.nix
    ./users.nix
  ];
}
