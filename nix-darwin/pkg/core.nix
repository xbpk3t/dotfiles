{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
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

    # 系统监控
    # htop
    # btop

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

    # 基础开发工具
    go
    gum
  ];
}
