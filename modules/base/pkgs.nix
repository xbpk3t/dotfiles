# Cross-platform shared package management
# Contains packages common to all platforms but not in minimal set
# Organized by category in a single systemPackages definition
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Basic utilities
    curl
    wget

    tree

    zip
    unzip

    # System utilities
    screen

    # Development tools
    gcc
    gnumake
    cmake

    dateutils # 操作日期和时间表达式 dateadd、datediff、strptime

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

    gnupg
    # 挪到base里，因为darwin和nixos都需要使用sops-nix
    sops
    age
    openssh

    croc # https://github.com/schollz/croc
  ];
}
