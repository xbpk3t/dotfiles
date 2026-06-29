{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./.;

  home.packages =
    with pkgs;
    [

      # 其他语言
      # php
      # elixir
      # android-tools

      lua

      # https://github.com/johnnymorganz/stylua
      # lua formater
      stylua

      # haskell
      # cabal-install
    ]
    ++ [
      # Development tools
      gcc
      gnumake
      cmake

    ];

  # stylua config: managed by treefmt (home/base/langs/treefmt.nix)
}
