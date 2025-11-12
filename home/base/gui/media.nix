{pkgs, ...}: {
  # https://mynixos.com/home-manager/options/programs.mpv
  programs.mpv = {
    enable = true;
    bindings = {
      WHEEL_UP = "add volume 5";
      WHEEL_DOWN = "add volume -5";
      "Alt+h" = "add video-pan-x 0.05";
      "Alt+l" = "add video-pan-x -0.05";
      "Alt+k" = "add video-pan-y 0.05";
      "Alt+j" = "add video-pan-y -0.05";
    };
    config = {
      hwdec = true;
      save-position-on-quit = true;
      profile = "gpu-hq";
      force-window = true;
      # hwdec = auto;
      ao = "pipewire,alsa,coreaudio";
      ytdl-format = "bestvideo+bestaudio";
      cache-default = 4000000;
    };
  };

  programs.yt-dlp = {
    enable = true;
    package = pkgs.yt-dlp;
  };

  # Local image editing and organizing
  home.packages = [
    pkgs.digikam
    pkgs.exiftool
  ];
}
