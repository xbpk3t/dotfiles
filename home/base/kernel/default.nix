{ mylib, pkgs, ... }:
{
  imports = mylib.scanPaths ./.;

  home.packages =
    with pkgs;
    [
      # 分类3：基础系统与文本处理工具

      # 基础工具

      # tags(desc): 基础工具 > Unix工具集 > 系统命令
      # coreutils

      # tags(desc): 基础工具 > 文件检索 > Unix
      # findutils
      # # tags(desc): 基础工具 > diff比较 > Unix
      # diffutils
      # # tags(desc): 基础工具 > 文本处理 > awk
      # gawk
      # # tags(desc): 基础工具 > 文本处理 > sed
      # gnused

      # 其他实用工具
      # tags(desc): 基础工具 > 监控观察 > 实时刷新
      # watch
      # rsync

      # 压缩工具
      ouch-rar
      xz
      zstd
    ]
    ++ [
      # === 磁盘使用分析 ===

      dua # du 替代（Rust）
      gdu # du 替代（Go）
      dysk # df 替代（Rust）
    ]
    ++ [

      xh # curl 替代（Rust）
      httpie
    ]
    ++ [
      curl
      # wget
      # screen
      # tree
      file
      which
      # dos2unix
    ]
    ++ [
      shellcheck
      shfmt
    ]
    ++ [ gum ];
}
