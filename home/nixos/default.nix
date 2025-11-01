{mylib, ...}: {
  imports = [../base] ++ mylib.scanPaths ./.;
}
