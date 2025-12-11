{pkgs, ...}: {
  home.packages = with pkgs; [
    # dotbot # 用nix的mkOutOfStoreSymlink代替了
    pre-commit

    # CICD
    # ansible  # Temporarily disabled due to hash mismatch in ncclient dependency
    opentofu
    cf-terraforming

    # 代码质量和分析
    shellcheck
    yamllint
    markdownlint-cli

    # https://mynixos.com/nixpkgs/package/kdlfmt
    # kdlfmt 的 pre-commit 仍然需要bin才能使用
    kdlfmt

    urlscan
    lychee

    cloudflared # cloudflare tunnel

    # https://github.com/cloudflare/workers-sdk
    # https://mynixos.com/nixpkgs/package/wrangler
    # wrangler

    # API 工具
    grpcurl

    # 基础工具
    coreutils
    findutils
    diffutils
    gawk
    gnused
    gnutar
    gzip

    # 其他实用工具
    watch
    rsync

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
    graphviz

    # static file server
    # https://mynixos.com/nixpkgs/package/dufs
    # https://github.com/sigoden/dufs
    # https://github.com/cnphpbb/deploy.stack/blob/main/dufs/config/config.yaml ???
    dufs
  ];
}
