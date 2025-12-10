{pkgs, ...}:
# media - control and enjoy audio/video
{
  home.packages = with pkgs; [
    # audio control
    pavucontrol # pulsemixer
    playerctl

    imv # simple image viewer

    # video/audio tools
    libva-utils
    vdpauinfo
    vulkan-tools

    mesa-demos # glxinfo

    nvitop
  ];

  services = {
    playerctld.enable = true;
  };
}
