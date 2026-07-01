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
      lua
      # stylua config: managed by treefmt (home/base/langs/treefmt.nix)
      stylua
    ]
    ++ [
      # Development tools
      gcc
      gnumake
      cmake
    ];
}
