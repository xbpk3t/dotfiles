{ pkgs, ... }:

{
  imports = [
    ./languages.nix
    ./development.nix
    ./networking.nix
    ./media.nix
    ./security.nix
    ./utilities.nix
  ];
}
