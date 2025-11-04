{
  lib,
  mylib,
  ...
}: let
  extraImports =
    lib.filter (path: builtins.baseNameOf (toString path) != "init.nix")
    (mylib.scanPaths ./.);
in {
  imports = [./init.nix] ++ extraImports;
}
