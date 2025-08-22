# NixOS-specific modules
{ ... }:

{
  imports = [
    ../../shared/packages.nix

    ./locale.nix
    ./boot.nix
    ./networking.nix
    ./services.nix
    ./security.nix
    ./system-limits.nix
    ./directories.nix
    ./users.nix
  ];
}
