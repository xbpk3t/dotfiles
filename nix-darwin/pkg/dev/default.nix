{ pkgs, ... }:

{
  imports = [
    ./langs.nix
    ./tools.nix
    ./containers.nix
  ];
}
