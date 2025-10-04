{
  pkgs,
  lib,
  ...
}:
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
    glxinfo
    nvitop
  ];

  programs.mpv = {
    enable = lib.mkDefault false;
    defaultProfiles = ["gpu-hq"];
    scripts = [pkgs.mpvScripts.mpris];
  };

  services = {
    playerctld.enable = true;
  };
}
