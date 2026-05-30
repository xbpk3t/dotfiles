{ pkgs, ... }:
{
  # 为啥选择 lazyjournal？
  # 目前没有对标工具，systemctl-tui, lnav, journal-viewer, sysz 这些在 journaltcl 场景下都不如 lazyjournal

  # sudo journalctl -u singbox -f
  # 这里的 -u 是啥意思？
  # 搭配
  # journalctl -u traefik --since "2026-01-10" --no-pager | tail -n 50

  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/lazyjournal
    # https://github.com/Lifailon/lazyjournal
    lazyjournal

    # 更成熟的通用日志分析器，适合搭配 journalctl
    # https://github.com/tstack/lnav
    # https://mynixos.com/nixpkgs/package/lnav
  ];

  home.file.".config/lazyjournal/config.yml" = {
    source = ./lazyjournal.yml;
    force = true;
  };
}
