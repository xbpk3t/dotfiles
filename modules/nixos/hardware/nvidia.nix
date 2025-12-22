{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption mkDefault types;
  cfg = config.modules.hardware.nvidia;
in {
  # ===============================================================================================
  # for Nvidia GPU
  # https://wiki.nixos.org/wiki/NVIDIA
  # https://wiki.hyprland.org/Nvidia/
  # ===============================================================================================

  options.modules.hardware.nvidia = {
    enable = mkEnableOption "enable NVIDIA GPU support";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        Override the NVIDIA driver package. Leave null to use the kernelPackages
        production driver (or legacy_470 on older GPUs via host override).
      '';
    };

    open = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to use the open kernel module (if supported).";
    };

    modesetting = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DRM modesetting (required for Wayland compositors).";
    };

    powerManagement = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NVIDIA power management.";
    };

    enableContainerToolkit = mkOption {
      type = types.bool;
      default = true;
      description = "Enable nvidia-container-toolkit for CUDA in containers.";
    };

    enable32Bit = mkOption {
      type = types.bool;
      default = true;
      description = "Enable 32-bit graphics stack (needed for some apps and Steam).";
    };

    addKernelParamFbdev = mkOption {
      type = types.bool;
      default = true;
      description = "Add nvidia-drm.fbdev=1 to kernel params for Wayland.";
    };
  };

  config = mkIf cfg.enable {
    boot.kernelParams = lib.mkIf cfg.addKernelParamFbdev [
      # Since NVIDIA does not load kernel mode setting by default,
      # enabling it is required to make Wayland compositors function properly.
      "nvidia-drm.fbdev=1"
    ];

    # will install nvidia-vaapi-driver by default
    services.xserver.videoDrivers = ["nvidia"];

    hardware.graphics = {
      enable = true;
      enable32Bit = cfg.enable32Bit;
    };

    hardware.nvidia = {
      open = cfg.open;
      package = mkDefault (
        if cfg.package != null
        then cfg.package
        else config.boot.kernelPackages.nvidiaPackages.production
      );

      modesetting.enable = cfg.modesetting;
      powerManagement.enable = cfg.powerManagement;
      nvidiaSettings = true;
    };

    hardware.nvidia-container-toolkit.enable = cfg.enableContainerToolkit;

    # Wayland/VA-API friendly env for NVIDIA
    environment.variables = {
      # for hyprland with nvidia gpu" = " ref https://wiki.hyprland.org/Nvidia/
      "LIBVA_DRIVER_NAME" = "nvidia";
      "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";

      # VA-API hardware video acceleration
      "NVD_BACKEND" = "direct";

      "GBM_BACKEND" = "nvidia-drm";
    };
  };
}
