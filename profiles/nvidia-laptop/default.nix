{...}: let
  inherit (import ../../../../hosts/nixos/default/variables.nix) intelID nvidiaID;
in {
  imports = [
    ../../../../hosts/nixos/default
    ../../drivers
    ../../core
  ];
  # Enable GPU Drivers
  drivers = {
    amdgpu.enable = false;
    nvidia.enable = true;
    nvidia-prime = {
      enable = true;
      intelBusID = "${intelID}";
      nvidiaBusID = "${nvidiaID}";
    };
    intel.enable = false;
  };
  vm.guest-services.enable = false;
}
