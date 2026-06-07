{
  mylib,
  pkgs,
  ...
}:
{
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

  # stylua config: managed by treefmt (home/base/langs/treefmt.nix)
}
