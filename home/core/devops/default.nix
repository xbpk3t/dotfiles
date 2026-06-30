{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    curl
    wget
    screen
    tree
    file
    which
  ];
}
