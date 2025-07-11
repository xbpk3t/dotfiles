{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 基础媒体处理
    ffmpeg

    # 音频处理
    # sox
    # lame

    # 图像处理
    imagemagick
    exiftool
  ];
}
