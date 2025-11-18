{
  lib,
  mylib,
  ...
}: let
  inherit (lib) filter;
  modulePaths = filter (path: path != ./lib) (mylib.scanPaths ./.);
in {
  imports = modulePaths;
}
