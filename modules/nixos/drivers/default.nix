{...}: {
  imports = [
    ./amd-drivers.nix
    ./intel-drivers.nix
    ./local-hardware-clock.nix
    ./nvidia-drivers.nix
    ./nvidia-prime-drivers.nix
    ./nvidia-amd-hybrid.nix
    ./vm-guest-services.nix
  ];
}
