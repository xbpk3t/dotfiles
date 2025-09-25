# Shared modules between all systems
{mylib, ...}: {
  imports = mylib.scanPaths ./.;
}
