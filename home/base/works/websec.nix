{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.works.websec;
in
{
  # host:
  #   modules.works.websec.enable = true;
  #
  # ⚠️ 安全工具较重：nuclei ~135M、sqlmap ~33M、katana ~66M。按需开启。

  options.modules.works.websec = with lib; {
    enable = mkEnableOption "web security tools (katana / nuclei / sqlmap)";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        # 渗透测试
        katana

        # 漏洞分析
        nuclei

        nuclei-templates

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
  };
}
