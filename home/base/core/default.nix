{
  mylib,
  pkgs,
  ...
}: {
  imports = [../init.nix] ++ mylib.scanPaths ./.;

  # 注意之前这部分在 modules/base 里，以供darwin, nixos 复用。但是实际上应该挪到home里，同样来复用这些pkg
  home.packages = with pkgs;
    [
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

      # 证书和密钥管理
      # [2026-01-15] 需要在目标host上检查证书问题
      openssl
    ]
    ++
    # 之前放在 hosts/nixos-vps 里，但是实际上VPS并不需要这两个pkg，所以放在homelab里
    [
      # https://mynixos.com/nixpkgs/package/nixos-anywhere
      # 因为可能之后也会用mac作为核心控制端，所以直接放到base里，来多端复用（而非放到专门nixos的nix文件里）
      # 之所以放在这里，因为无论是nixos还是mac都会引入 home/base/desktop，严格对应关系引用
      nixos-anywhere

      # 同上，同样只有workstation才有必要引入colmena
      colmena
    ];
}
