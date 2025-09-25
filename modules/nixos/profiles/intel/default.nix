{...}: {
  imports = [
    ../../hosts/default
    ../../modules/drivers
    ../../modules/core
  ];
  # Enable GPU Drivers
  drivers = {
    amdgpu.enable = false;
    nvidia.enable = false;
    nvidia-prime.enable = false;
    intel.enable = true;
  };
  vm.guest-services.enable = false;
}
