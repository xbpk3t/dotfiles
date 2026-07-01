{
  pkgs,
  mylib,
  config,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # 分类1：质量检查与规范化
      # 用nix的mkOutOfStoreSymlink代替了
      # dotbot

      # tags(desc): 代码质量 > 提交钩子 > 自动化
      pre-commit
      prek

      dos2unix

      # tags(desc): 代码质量 > URL提取检查 > 文本分析
      urlscan
      # tags(desc): 代码质量 > 链接校验 > 文档检查
      lychee
    ]
    ++ [
      # 分类3：基础系统与文本处理工具

      # 基础工具
      #
      # [2026-01-25]
      # https://mynixos.com/nixpkgs/package/coreutils-prefixed
      # why: For stdbuf/gstdbuf. 需要 stdbuf 来实现 用于并行执行时让日志实时刷新、减少输出延迟/卡住的情况。
      # what: 并不需要 coreutils-prefixed (这个pkg会提供一套 g* 的命令，以与 coreutils 避免冲突)，仅作记录
      #
      # tags(desc): 基础工具 > Unix工具集 > 系统命令
      coreutils

      # tags(desc): 基础工具 > 文件检索 > Unix
      findutils
      # tags(desc): 基础工具 > diff比较 > Unix
      diffutils
      # tags(desc): 基础工具 > 文本处理 > awk
      gawk
      # tags(desc): 基础工具 > 文本处理 > sed
      gnused
      # tags(desc): 基础工具 > 归档打包 > tar
      gnutar
      # tags(desc): 基础工具 > 压缩 > gzip
      gzip

      # 其他实用工具
      # tags(desc): 基础工具 > 监控观察 > 实时刷新
      watch
      rsync

      # 压缩工具
      ouch-rar
      xz
      zstd
    ]
    ++ [
      # 分类4：媒体处理与可视化工具

      # 基础媒体处理
      # tags(desc): 媒体处理 > 视频音频 > 转码
      ffmpeg

      # 音频处理
      # sox
      # lame

      # 图像处理
      # tags(desc): 媒体处理 > 图像编辑 > 转换
      imagemagick

      # cwebp. WebP官方工具
      # tags(desc): 媒体处理 > 图像编码 > WebP
      libwebp

      # tags(desc): 媒体处理 > 元数据 > 图像信息
      exiftool
      # tags(desc): 可视化 > 图绘制 > 图结构
      graphviz

      # static file server
      # https://github.com/sigoden/dufs
      # https://github.com/cnphpbb/deploy.stack/blob/main/dufs/config/config.yaml ???
      # tags(desc): 文件服务 > 静态分发 > HTTP
      dufs
    ];

  home.sessionVariables = {
    TAILSCALE_API_KEY = "$(cat ${config.sops.secrets.TAILSCALE_API_KEY.path})";
  };

  imports = mylib.scanPaths ./.;
}
