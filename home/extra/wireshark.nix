{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.extra.wireshark;
in {
  options.modules.extra.wireshark = with lib; {
    enable = mkEnableOption "Wireshark user-space tools";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      lib.optionals pkgs.stdenv.isLinux
      (with pkgs; [
        # https://mynixos.com/nixpkgs/package/wireshark
        # https://www.wireshark.org/
        # 正如 modules/wireshark 所说，在 darwin/nixos 拆分安装 wireshark
        # wireshark

        # Wireshark-TUI
        # https://mynixos.com/nixpkgs/package/termshark
        # https://github.com/gcla/termshark
        # [2026-04-08] 注释掉了，两方面：
        ## 1、【生态位尴尬】主力场景还是GUI，暂时没有 SSH上直接查看目标机器wireshark的需求。如果轻量场景直接用 tshark，复杂功能则传回workstation直接用 wireshark 查看。
        ## 2、综合来说，termshark 只能覆盖 30%-40% wireshark 本身的能力。
        ## 3、已经EOL很久了
        # termshark

        # wireshark-cli
        # https://mynixos.com/nixpkgs/package/tshark
        # 本身就内置了以下命令
        #  - tshark
        #  - dumpcap
        #  - editcap
        #  - mergecap
        #  - text2pcap
        #  - capinfos
        #  - captype
        #  - rawshark
        #  - reordercap
        #  - randpkt
        #  - sharkd
        tshark

        #  ngrep 适合“先快速定位，再进入深分析”。
        #
        #  典型搭配流程：
        #
        #  1. 先用 ngrep 快速看有没有你关心的内容
        #     比如某个 Host、某个 HTTP 路径、某个明文关键字。
        #     它适合回答：
        #     “这台机器到底有没有发出这个请求？”
        #     “流量里有没有出现这个字符串？”
        #     “哪个连接里带了这个 header / payload？”
        #  2. 定位到问题后，再用 tshark / termshark / wireshark 深入分析
        #     比如：
        #
        #  - 看协议字段
        #  - 跟踪 TCP stream
        #  - 看重传、乱序、握手失败
        #  - 做 display filter
        #  - 看完整 pcap 结构
        #
        #  可以把它理解成：
        #
        #  - ngrep：网络里的 grep
        #  - tshark：网络里的结构化解析器
        #  - termshark：tshark 的交互 TUI
        #  - wireshark：最完整的 GUI 分析器
        #
        #  一个很实际的分工是：
        #
        #  - 想快速确认“有没有某段内容” -> ngrep
        #  - 想精确过滤字段、导出、统计 -> tshark
        #  - 想在终端里交互浏览 -> termshark
        #  - 想最完整地分析 -> wireshark
        # https://mynixos.com/nixpkgs/package/ngrep
        ngrep

        #- zeek
        #  太重，已经不是同一层级的工具。
        #- pyshark
        #  这是 Python 库，不是你这个 home.packages 文件的合适层。
        #- tcpreplay
        #  只有你明确有 pcap 回放需求时再加。
        #- netsniff-ng
        #  更偏专用网络工具，不是 Wireshark 主线工作流必需。
      ]);
  };
}
