# NixOS-specific modules
{...}: {
  imports = [
    ./boot.nix
    ./networking.nix
    ./pkgs.nix
    ./ssh.nix
    ./users.nix
    ./swap.nix
    ./limits.nix
    ./systemd.nix
  ];
}
