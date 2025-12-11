# Darwin-specific modules
{mylib, ...}: {
  imports = [../base] ++ mylib.scanPaths ./.;
}
