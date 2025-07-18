{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
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

  imports = [
    ./network.nix
    ./db.nix
    ./langs.nix
    ./ts.nix
    ./golang.nix
    ./devops.nix
    ./git.nix
    ./test.nix
    ./k8s.nix
  ];
}
