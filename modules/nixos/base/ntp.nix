{
  lib,
  ...
}:
{
  # Network performance optimization
  # These are safe, widely-used network optimization parameters
  # that improve performance for both desktop and server environments
  # Use an NTP server located in the mainland of China to synchronize the system time
  networking.timeServers = [
    "ntp.aliyun.com" # Aliyun NTP Server
    "ntp.tencent.com" # Tencent NTP Server
  ];

  # NixOS 默认启用的是 systemd-timesyncd，这是 systemd 自带的一个轻量 SNTP（简化版 NTP）客户端，用来自动同步时间。NixOS 的 NTP 文档里明确说默认 NTP 实现是 systemd-timesyncd。
  # https://mynixos.com/nixpkgs/options/services.chrony

  # 想让这台机器 给别的机器当时间服务器（NTP/NTS server）
  # 对时间精度有比较高的要求（日志对齐、多机事务、金融、监控等）：需要 毫秒甚至更优
  # 机器 经常睡眠/断网/虚拟化环境多，网络质量比较复杂
  # ➜ 更推荐 chrony：功能更强、精度更高、对「不稳定环境」适配更好。
  # 「懒得折腾 + 一般用途」：留在 NixOS 默认的 systemd-timesyncd ✅
  # 「要精度、要 NTS、要当时间服务器」：换到 chrony ✅
  services.timesyncd.enable = lib.mkDefault true;

  # dynamically update /etc/hosts for testing
  # Note that changes made in this way will be discarded when switching configurations.
  environment.etc.hosts.mode = "0644";

  # PLAN[2026-01-20]: https://github.com/kaseiwang/flakes/blob/master/nixos/n3160/networking.nix#L294
  #
  # https://mynixos.com/nixpkgs/options/services.hostapd
  # services.hostapd
  # services.kaseinet
  # services.smartdns
  # services.ddns
  # services.ntpd-rs
  # services.resolved
  # services.chinaRoute
}
