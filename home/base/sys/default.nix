{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/redocly
    # https://github.com/Redocly/redocly-cli
    # redocly
  ];
}
