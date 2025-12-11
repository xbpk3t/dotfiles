{pkgs, ...}: {
  home.packages = with pkgs; [
    # 网络工具 (excluding wget/curl which are in minimal)

    # 经常需要在目标host上手动使用这些cli来检查和判断具体问题

    mosh
    fping
    inetutils
    # https://mynixos.com/nixpkgs/package/dig
    dig
    mtr

    nexttrace # 可视化路由跟踪工具

    gping # ping, but with a graph(TUI)
    #  doggo # DNS client for humans

    duf # Disk Usage/Free Utility - a better 'df' alternative
    #  du-dust # A more intuitive version of `du` in rust

    # wifi with TUI
    # https://github.com/pythops/impala
    # https://mynixos.com/nixpkgs/package/impala
    # 只有个人的minimal机器需要（VPS或者desktop都用不到）
    impala

    # dis
    ncdu

    # rename
    rnr # https://github.com/ismaelgv/rnr
  ];
}
