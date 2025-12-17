{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs;
    [
      # 网络工具 (excluding wget/curl which are in minimal)
      mosh
      fping
      inetutils
      # https://mynixos.com/nixpkgs/package/dig
      dig
      mtr

      gping # ping, but with a graph(TUI)
      #  doggo # DNS client for humans

      duf # Disk Usage/Free Utility - a better 'df' alternative
      #  du-dust # A more intuitive version of `du` in rust

      ncdu

      # rename
      rnr # https://github.com/ismaelgv/rnr
    ]
    # Linux-only tools; Darwin 上直接跳过，避免 hostPlatform 不可用的求值错误
    ++ lib.optionals stdenv.isLinux [
      # nexttrace 可视化路由跟踪工具
      nexttrace

      # wifi with TUI
      # https://github.com/pythops/impala
      # https://mynixos.com/nixpkgs/package/impala
      # 只有个人的minimal机器需要（VPS或者desktop都用不到）
      # impala（Wi‑Fi TUI），仅在 Linux 上可用
      impala
    ];
}
