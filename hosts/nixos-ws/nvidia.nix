{config, ...}: {
  # ===============================================================================================
  # for Nvidia GPU
  # https://wiki.nixos.org/wiki/NVIDIA
  # https://wiki.hyprland.org/Nvidia/
  # ===============================================================================================

  boot.kernelParams = [
    # Since NVIDIA does not load kernel mode setting by default,
    # enabling it is required to make Wayland compositors function properly.
    "nvidia-drm.fbdev=1"
  ];

  services.xserver.videoDrivers = ["nvidia"]; # will install nvidia-vaapi-driver by default

  hardware.nvidia = {
    # MX350 是 legacy GPU，使用闭源驱动
    open = false;
    # 使用 470.xx legacy 驱动，专门支持 Pascal 架构
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;

    # required by most wayland compositors!
    modesetting.enable = true;
    # legacy GPU 建议 false
    powerManagement.enable = false;
    nvidiaSettings = true;
  };

  hardware.nvidia-container-toolkit.enable = true;
  hardware.graphics = {
    enable = true;
    # needed by nvidia-docker
    enable32Bit = true;
  };

  # nixpkgs.overlays = [
  #   (_: super: {
  #     # ffmpeg-full = super.ffmpeg-full.override {
  #     #   withNvcodec = true;
  #     # };
  #   })
  # ];

  # 接受 NVIDIA 驱动license，否则无法build
  nixpkgs.config.nvidia.acceptLicense = true;
}
