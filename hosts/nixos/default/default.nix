{...}: {
  imports = [
    ./hardware.nix
    ../../../modules/nixos
  ];

  # Enable NVIDIA drivers since we have NVIDIA GPU
  drivers.nvidia.enable = true;
}
