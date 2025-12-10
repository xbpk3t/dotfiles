{
  pkgs,
  lib,
  ...
}: {
  # https://mynixos.com/home-manager/options/programs.mpv
  programs.mpv = {
    enable = lib.mkDefault false;
    defaultProfiles = ["gpu-hq"];
    scripts = [pkgs.mpvScripts.mpris];
  };
}
