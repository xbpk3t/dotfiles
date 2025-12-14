# Darwin-specific modules
{mylib, ...}: {
  imports = mylib.scanPaths ./.;

  # Determinate uses its own daemon to manage the Nix installation that conflicts with nix-darwin’s native Nix management. To turn off nix-darwin’s management of the Nix installation.
  nix.enable = false;
}
