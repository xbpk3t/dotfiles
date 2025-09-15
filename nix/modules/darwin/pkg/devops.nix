{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # 构建和任务工具
    go-task
    dotbot
    pre-commit

    # CICD
    # ansible  # Temporarily disabled due to hash mismatch in ncclient dependency
    opentofu
    cf-terraforming

    # 代码质量和分析
    shellcheck
    yamllint
    markdownlint-cli

    urlscan
    lychee

    cloudflared # cloudflare tunnel

    # wrangler # https://github.com/cloudflare/workers-sdk

    # 环境管理 (已移至 home-manager)
    # direnv

    # API 工具
    grpcurl

    # 其他开发工具
    graphviz

    # 基础工具
    coreutils
    findutils
    diffutils
    gawk
    gnused
    gnutar
    gzip

    # 文件处理
    tree
    file
    which

    # 压缩工具
    zip
    unzip
    p7zip
    xz
    zstd

    # 其他实用工具
    watch
    rsync
    cowsay

    # 证书和密钥管理
    openssl

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
