{
  pkgs,
  mylib,
  ...
}: {
  home.packages = with pkgs; [
    # 用nix的mkOutOfStoreSymlink代替了
    # dotbot

    # https://mynixos.com/nixpkgs/package/pre-commit
    pre-commit

    # https://mynixos.com/nixpkgs/package/dos2unix
    #
    # [2026-01-24] 遇到了 CRLF 换行符 问题。
    # yamllint 报 wrong new line character: expected \n 期望 LF，但文件是 CRLF。
    # 可以直接用 dos2unix manifests/**/kustomization.yaml 批量解决问题
    dos2unix

    # 代码质量和分析
    shellcheck
    typos
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
    #
    # [2026-01-25]
    # https://mynixos.com/nixpkgs/package/coreutils-prefixed
    # why: For stdbuf/gstdbuf. 需要 stdbuf 来实现 用于并行执行时让日志实时刷新、减少输出延迟/卡住的情况。
    # what: 并不需要 coreutils-prefixed (这个pkg会提供一套 g* 的命令，以与 coreutils 避免冲突)，仅作记录
    #
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

    # 基础媒体处理
    ffmpeg

    # 音频处理
    # sox
    # lame

    # 图像处理
    imagemagick

    # cwebp. WebP官方工具
    # https://mynixos.com/nixpkgs/package/libwebp
    libwebp

    exiftool
    graphviz

    # static file server
    # https://mynixos.com/nixpkgs/package/dufs
    # https://github.com/sigoden/dufs
    # https://github.com/cnphpbb/deploy.stack/blob/main/dufs/config/config.yaml ???
    dufs

    # https://mynixos.com/nixpkgs/package/dogdns
    # DNS 查询与诊断工具
    # 'dogdns' has been removed as it is unmaintained upstream and vendors insecure dependencies. Consider switching to 'doggo', a similar tool.
    # dogdns
    # doggo

    # https://mynixos.com/nixpkgs/package/termshark
    # 基于终端界面的 Wireshark
    termshark

    # https://mynixos.com/nixpkgs/package/ipcalc
    # 计算子网掩码/网段
    ipcalc
  ];

  imports = mylib.scanPaths ./.;
}
