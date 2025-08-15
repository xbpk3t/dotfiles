# Shared modules for all platforms (Darwin and NixOS)
{ ... }:

{
  imports = [
    ./packages.nix
    ./users.nix
    ./timezone.nix
    ./ssh.nix
    ./system-limits.nix
    ./directories.nix
    ./git.nix
  ];
}
