{pkgs, ...}: {
  home.packages = with pkgs; [
    # tcpdump 网络抓包
    # [2026-01-07] VPS上需要通过tcpdump抓包来排查问题，所以挪到core里
    tcpdump
  ];
}
