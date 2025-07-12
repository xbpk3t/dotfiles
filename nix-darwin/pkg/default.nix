{ pkgs, ... }:

{
  imports = [
    ./core.nix
    ./dev
    ./network.nix
    ./security.nix
    ./database.nix
    ./media.nix
  ];
}
