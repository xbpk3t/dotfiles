{ mylib, pkgs, ... }:
{
  imports = mylib.scanPaths ./.;

  home.packages =
    with pkgs;
    [

      # Development tools
      gcc
      gnumake
      cmake
    ]
    ++ [
      # 分类3：基础系统与文本处理工具

      # 基础工具

      # tags(desc): 基础工具 > Unix工具集 > 系统命令
      # coreutils

      # tags(desc): 基础工具 > 文件检索 > Unix
      findutils
      # tags(desc): 基础工具 > diff比较 > Unix
      diffutils
      # tags(desc): 基础工具 > 文本处理 > awk
      gawk
      # tags(desc): 基础工具 > 文本处理 > sed
      gnused

      # 其他实用工具
      # tags(desc): 基础工具 > 监控观察 > 实时刷新
      watch
      rsync

      # 压缩工具
      ouch-rar
      xz
      zstd
    ];
}
