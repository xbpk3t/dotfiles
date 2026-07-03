{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # === HTTP 客户端 ===
    xh # curl 替代（Rust）
    httpie
    # === 下载工具 ===

    # === 磁盘使用分析 ===
    dua # du 替代（Rust）
    gdu # du 替代（Go）

    # === 磁盘信息 ===
    dysk # df 替代（Rust）

    # === 代码质量与提交 ===
    commitizen
    python3Packages.pre-commit-hooks

    # === CLI 增强 ===
    gum

    # === 文档/排版工具 ===
    # typst
    # typstyle
  ];
}
