{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.drivers.nvidia-amd-hybrid;
in {
  options.drivers.nvidia-amd-hybrid = {
    enable = mkEnableOption "Enable AMD iGPU + NVIDIA dGPU (Prime offload)";
    # AMD iGPU Bus ID (e.g., PCI:5:0:0). Expose as option for future host wiring.
    amdgpuBusID = mkOption {
      type = types.str;
      default = "PCI:5:0:0";
      description = "PCI Bus ID for AMD iGPU (amdgpuBusId)";
    };
    # NVIDIA dGPU Bus ID (e.g., PCI:1:0:0)
    nvidiaBusID = mkOption {
      type = types.str;
      default = "PCI:1:0:0";
      description = "PCI Bus ID for NVIDIA dGPU (nvidiaBusId)";
    };
  };

  config = mkIf cfg.enable {
    # Enforce kernel 6.12 when this hybrid config is selected
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;

    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;
      open = true; # RTX 50xx requires the open kernel module
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;

      # Helpful on laptops to power down the dGPU when idle
      powerManagement.enable = true;
      powerManagement.finegrained = true;

      # AMD primary, NVIDIA offload
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        # Wire from options
        amdgpuBusId = cfg.amdgpuBusID;
        nvidiaBusId = cfg.nvidiaBusID;
      };
    };
  };
}
