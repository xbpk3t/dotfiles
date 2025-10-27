{pkgs, ...}: {
  home.packages = with pkgs; [
    # 网络工具 (excluding wget/curl which are in minimal)
    mosh
    fping
    inetutils
    mtr
    nexttrace # 可视化路由跟踪工具

    gping # ping, but with a graph(TUI)
    #  doggo # DNS client for humans
    #  duf # Disk Usage/Free Utility - a better 'df' alternative
    #  du-dust # A more intuitive version of `du` in rust

    # wifi with TUI
    # https://github.com/pythops/impala
    # https://mynixos.com/nixpkgs/package/impala
    impala

    # disk
    ncdu

    # rename
    rnr # https://github.com/ismaelgv/rnr
  ];
}
