{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # https://github.com/Redocly/redocly-cli
    # redocly
  ];
}
