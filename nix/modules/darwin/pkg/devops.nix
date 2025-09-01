{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 构建和任务工具
    go-task
    dotbot
    pre-commit

    # CICD
    ansible
    opentofu
    cf-terraforming


    # 代码质量和分析
    shellcheck
    yamllint
    markdownlint-cli

    urlscan
    lychee

    cloudflared # cloudflare tunnel

    wrangler # https://github.com/cloudflare/workers-sdk

    # 环境管理
    direnv

    # API 工具
    grpcurl

    # 其他开发工具
    graphviz

    fastfetch

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
    bat
    fd
    ripgrep
    file
    which

    # 压缩工具
    zip
    unzip
    p7zip
    xz
    zstd

    # 文本处理
    jq
    yq-go

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
    webp
    exiftool

    # Docker
    hadolint

    # git
    # gh is in shared/packages.nix
    git-lfs
    git-quick-stats # https://github.com/git-quick-stats/git-quick-stats
    gitleaks
    gitlint
    bfg-repo-cleaner
    ugit
    git-who # https://github.com/sinclairtarget/git-who 一个开源的命令行工具，显示 Git 仓库的提交者统计。
  ];
}
