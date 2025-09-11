# NixOS boot configuration
# Contains boot configuration that can be shared between multiple hosts
{...}: {
  # Shared boot configuration
  boot = {
    # Shared kernel modules
    initrd.kernelModules = [];
    kernelModules = [];
    extraModulePackages = [];
  };

  # Shared file systems configuration
  fileSystems = {};

  # Shared swap configuration
  swapDevices = [];

  # Shared system state version
  # Note: This should be host-specific and is kept here as an example
  # In practice, system.stateVersion should be set in host-specific configuration
  # system.stateVersion = "24.05";
}
