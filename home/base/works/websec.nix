{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # 渗透测试
      # https://github.com/projectdiscovery/katana
      katana

      # 漏洞分析
      # https://github.com/projectdiscovery/nuclei
      nuclei

      nuclei-templates
      # nucleiparser（nuclei 结果解析器，极少单独使用）
      # nucleiparser

      # 自动化 SQL 注入工具
      # https://github.com/sqlmapproject/sqlmap
      sqlmap

      # ffuf
      # caido-cli                     # tags(desc): Web代理 > 轻量级 > CLI模式(Rust)
      # caido-desktop                 # tags(desc): Web代理 > 轻量级 > GUI桌面
      # whatweb
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类1：Web 代理 & 模糊测试（Linux-only）
      # https://portswigger.net/burp
      # burpsuite 在 aarch64-darwin 上拉 glibc，仅 Linux 可用
      # burpsuite                     # tags(desc): Web代理 > 渗透测试 > 行业标准
    ];
}
