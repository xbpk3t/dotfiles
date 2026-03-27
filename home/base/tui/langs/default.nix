{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/devenv
    devenv

    # 其他语言
    # php
    # elixir
    # android-tools

    lua

    # https://mynixos.com/nixpkgs/package/stylua
    # https://github.com/johnnymorganz/stylua
    # lua formater
    stylua

    # haskell
    # cabal-install
  ];

  xdg.configFile.".stylua.toml".text = builtins.readFile ./stylua.toml;
}
