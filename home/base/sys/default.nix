{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # redocly
  ];
}
