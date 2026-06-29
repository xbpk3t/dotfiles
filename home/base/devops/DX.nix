{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # === HTTP 客户端 ===
    xh # curl 替代（Rust）

    # === 下载工具 ===

    # === 磁盘使用分析 ===
    dua # du 替代（Rust）
    gdu # du 替代（Go）

    # === 磁盘信息 ===
    dysk # df 替代（Rust）

  ];
}
