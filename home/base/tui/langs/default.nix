{
  mylib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/devenv
    devenv

    # 其他语言
    # php
    # elixir
    # android-tools

    lua

    # haskell
    # cabal-install
  ];

  imports = mylib.scanPaths ./.;
}
