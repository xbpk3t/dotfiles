# NixOS-specific modules
{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./services.nix
    ./security.nix
    ./system-limits.nix
    ./directories.nix
    ./users.nix
  ];
}
