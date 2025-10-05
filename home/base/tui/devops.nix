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

    urlscan
    lychee

    cloudflared # cloudflare tunnel

    # wrangler # https://github.com/cloudflare/workers-sdk

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
    graphviz

    devbox # [devbox - MyNixOS](https://mynixos.com/nixpkgs/package/devbox)
  ];
}
