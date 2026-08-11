{
  pkgs,
  mylib,
  config,
  ...
}:
with pkgs;
{
  home.packages =
    # pre-commit 依赖工具集（单一事实来源 lib/precommit-tools.nix，与 CI devShell 共用）
    mylib.precommitTools { inherit pkgs; }

    ++ [
      # 分类1：质量检查与规范化
      # 用nix的mkOutOfStoreSymlink代替了
      # dotbot

      # tags(desc): 代码质量 > URL提取检查 > 文本分析
      prek
      pre-commit
      python3Packages.pre-commit-hooks

      xurls
      # tags(desc): 代码质量 > 链接校验 > 文档检查
      lychee
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

    ];

  home.sessionVariables = {
    TAILSCALE_API_KEY = "$(cat ${config.sops.secrets.TAILSCALE_API_KEY.path})";
  };

  imports = mylib.scanPaths ./.;
}
