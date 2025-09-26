{...}: {
  imports = [
    ../../../../hosts/nixos/default
    ../../modules/drivers
    ../../core
  ];
  # Enable GPU Drivers
  drivers = {
    amdgpu.enable = true;
    nvidia.enable = false;
    nvidia-prime.enable = false;
    intel.enable = false;
  };
  vm.guest-services.enable = false;
}
