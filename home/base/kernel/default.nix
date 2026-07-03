{ mylib, pkgs, ... }:
{
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [

    # Development tools
    gcc
    gnumake
    cmake
  ];
}
