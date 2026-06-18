{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # === HTTP 客户端 ===
    # 【2026-06-18】从 home/base/infra/default.nix 迁入
    curl
    xh # curl 替代（Rust）

    # === 下载工具 ===
    # 【2026-06-18】从 home/base/infra/default.nix 迁入
    wget

    # === 磁盘使用分析 ===
    dua # du 替代（Rust）
    gdu # du 替代（Go）

    # === 磁盘信息 ===
    dysk # df 替代（Rust）

    # === 文件/目录工具 ===
    # 【2026-06-18】从 home/base/infra/default.nix 迁入
    tree
    file
    which

    # === 终端复用 ===
    # 【2026-06-18】从 home/base/infra/default.nix 迁入
    screen
  ];
}
