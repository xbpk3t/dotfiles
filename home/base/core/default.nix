{mylib, ...}: {
  imports = [../init.nix] ++ mylib.scanPaths ./.;
}
