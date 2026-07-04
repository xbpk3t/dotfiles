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

      gcc

      cmake
    ]
    ++ [
      lua
      # stylua config: managed by treefmt (home/base/langs/treefmt.nix)
      stylua
    ];
}
