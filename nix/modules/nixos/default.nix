# NixOS-specific modules
{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./packages.nix
    ./ssh.nix
    ./users.nix
    ./swap.nix
    ./limits.nix
  ];
}
