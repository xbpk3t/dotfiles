{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.desktop.media.mpv;
in {
  options.modules.desktop.media.mpv = with lib; {
    enable = mkEnableOption "mpv 播放器及快捷键配置";
  };

  config = lib.mkIf cfg.enable {
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

      defaultProfiles = ["gpu-hq"];
      scripts = [pkgs.mpvScripts.mpris];
    };
  };
}
