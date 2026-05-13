{config, ...}: {
  # https://github.com/yt-dlp/yt-dlp
  # https://mynixos.com/nixpkgs/package/yt-dlp
  # https://mynixos.com/home-manager/options/programs.yt-dlp
  programs.yt-dlp = {
    enable = true;

    settings = {
      # 保留一个低干扰的默认输出模板，适合平时手动抓取单个资源时直接复用。
      output = "%(title)s [%(id)s].%(ext)s";

      # 只保留下载归档这种通用增量能力；字幕语言、下载器、媒体后处理交给具体场景显式声明。
      download-archive = "${config.xdg.stateHome}/yt-dlp-archive.log";
    };

    extraConfig = ''
      # 只保留一个手动场景 alias，避免把字幕流水线不需要的默认行为重新绑回全局配置。
      --alias get-audio "-f ba --extract-audio --audio-format best --audio-quality 0"
    '';

    #    settings =
    #      {
    #        # 默认文件名保留标题和视频 ID，减少重名覆盖，但不强绑定固定下载目录。
    #        output = "%(title)s [%(id)s].%(ext)s";
    #
    #        # 默认优先下载分离的视频流和音频流；拿不到时再回退到单文件格式。
    #        format = "bv*+ba/b";
    #
    #        # 合并时优先产出 mp4，失败再回退到 mkv，兼顾通用兼容性和成功率。
    #        merge-output-format = "mp4/mkv";
    #
    #        # 默认把缩略图嵌进媒体文件，方便本地播放器和媒体库直接识别封面。
    #        embed-thumbnail = true;
    #
    #        # 先把缩略图转成 jpg，再走嵌入流程，兼容性比原图格式更稳。
    #        convert-thumbnails = "jpg";
    #
    #        # 默认把标题、作者、发布日期等元数据写回媒体文件。
    #        embed-metadata = true;
    #
    #        # 默认保留章节信息，便于播放器按章节跳转。
    #        embed-chapters = true;
    #
    #        # 默认直接把字幕嵌进媒体文件，不额外保留独立字幕文件。
    #        embed-subs = true;
    #
    #        # 默认抓取全部字幕，但排除 live_chat，避免把聊天回放也当成普通字幕。
    #        sub-langs = "all,-live_chat";
    #
    #        # 使用 aria2 做外部下载器，提高多连接下载的稳定性和吞吐。
    #        downloader = lib.getExe pkgs.aria2;
    #
    #        # 给 aria2 开启断点续传和适中的并发，不直接拉到特别激进的参数。
    #        downloader-args = "aria2c:'-c -x8 -s8 -k1M'";
    #
    #        # 用 XDG state 目录记录下载归档，适合长期增量抓取，也不依赖当前工作目录。
    #        download-archive = "${config.xdg.stateHome}/yt-dlp-archive.log";
    #      };
    ##      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    ##        # 只在 macOS 默认启用 Safari cookies；Linux 侧不强塞一个无效浏览器来源。
    ##        cookies-from-browser = "safari";
    ##      };

    #    extraConfig = ''
    #      # 场景型 alias：临时只抓音频时可用 `yt-dlp --get-audio URL`。
    #      # 这里复用默认 metadata / archive / cookies 行为，只把下载格式切到音频优先。
    #      --alias get-audio "-f ba --extract-audio --audio-format best --audio-quality 0"
    #    '';
  };
}
