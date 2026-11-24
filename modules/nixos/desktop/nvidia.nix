{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.modules.hardware.nvidia;
in
{
  # ===============================================================================================
  # NVIDIA 便利开关：真正的驱动选项由上游 nixpkgs 的 `hardware.nvidia` 模块提供。
  # 这里只做一层薄封装，把常用开关转成上游 option，避免再维护一份驱动配置。
  #
  # 需要 prime / datacenter / branch / gsp 等高级选项时，直接在 host 里设置
  # `hardware.nvidia.*`，不需要经过本模块。
  #
  #   https://wiki.nixos.org/wiki/NVIDIA
  # ===============================================================================================

  options.modules.hardware.nvidia = {
    enable = mkEnableOption "NVIDIA GPU support (thin wrapper around upstream hardware.nvidia)";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        Override the NVIDIA driver package. Leave null to use the upstream
        `hardware.nvidia.branch` default.
      '';
    };

    open = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Use the open kernel modules. Upstream requires this to be explicit on
        driver versions >= 560; set true on Turing or newer GPUs.
      '';
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

    # 上游 `hardware.nvidia` 模块通过这个列表判断是否启用 NVIDIA。
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      graphics = {
        enable = true;
        inherit (cfg) enable32Bit;
      };

      nvidia = {
        inherit (cfg) open;
        modesetting.enable = cfg.modesetting;
        powerManagement.enable = cfg.powerManagement;
        nvidiaSettings = true;
      }
      // lib.optionalAttrs (cfg.package != null) {
        # null 时不覆盖，让上游按 `hardware.nvidia.branch` 选择驱动；
        # 非 null 时用 mkDefault，仍允许 host 直接覆盖 hardware.nvidia.package。
        package = lib.mkDefault cfg.package;
      };

      nvidia-container-toolkit.enable = cfg.enableContainerToolkit;
    };

    # Wayland/VA-API friendly env for NVIDIA
    environment.variables = {
      # for hyprland with nvidia gpu; ref https://wiki.hyprland.org/Nvidia/
      "LIBVA_DRIVER_NAME" = "nvidia";
      "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";

      # VA-API hardware video acceleration
      "NVD_BACKEND" = "direct";

      "GBM_BACKEND" = "nvidia-drm";
    };
  };
}
