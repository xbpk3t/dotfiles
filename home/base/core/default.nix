{
  mylib,
  pkgs,
  ...
}: {
  imports = [../init.nix] ++ mylib.scanPaths ./.;

  # 注意之前这部分在 modules/base 里，以供darwin, nixos 复用。但是实际上应该挪到home里，同样来复用这些pkg
  home.packages = with pkgs; [
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
  ];
}
