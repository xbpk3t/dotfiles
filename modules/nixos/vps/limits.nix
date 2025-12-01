# NixOS system limits configuration
# Based on Linux-Optimizer project configurations for Ubuntu/Debian/CentOS/Fedora
# Contains system limits configuration that can be shared between multiple hosts
{
  config,
  lib,
  ...
}: let
  hostName = config.networking.hostName or null;
  flakeRef =
    if hostName == null
    then null
    else "/etc/nixos#${hostName}";
in {
  assertions = lib.optional (hostName == null) {
    assertion = false;
    message = "modules/nixos/vps/limits.nix expects networking.hostName to be defined.";
  };

  # System limits optimization (ulimit settings)
  # Based on Linux-Optimizer /etc/profile configurations
  security.pam.loginLimits = [
    # The maximum size of core files created
    {
      domain = "*";
      type = "-";
      item = "core";
      value = "unlimited";
    }
    # The maximum size of a process's data segment
    {
      domain = "*";
      type = "-";
      item = "data";
      value = "unlimited";
    }
    # The maximum size of files created by the shell (default option)
    {
      domain = "*";
      type = "-";
      item = "fsize";
      value = "unlimited";
    }
    # The maximum number of pending signals
    {
      domain = "*";
      type = "-";
      item = "sigpending";
      value = "unlimited";
    }
    # The maximum size that may be locked into memory
    {
      domain = "*";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
    # The maximum memory size
    {
      domain = "*";
      type = "-";
      item = "rss";
      value = "unlimited";
    }
    # The maximum number of open file descriptors
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = "1048576";
    }
    # The maximum POSIX message queue size
    {
      domain = "*";
      type = "-";
      item = "msgqueue";
      value = "unlimited";
    }
    # The maximum stack size (soft limit)
    {
      domain = "*";
      type = "-";
      item = "stack";
      value = "32768";
    }
    # The maximum stack size (hard limit)
    {
      domain = "*";
      type = "hard";
      item = "stack";
      value = "65536";
    }
    # The maximum number of seconds to be used by each process
    {
      domain = "*";
      type = "-";
      item = "cpu";
      value = "unlimited";
    }
    # The maximum number of processes available to a single user
    {
      domain = "*";
      type = "-";
      item = "nproc";
      value = "unlimited";
    }
    # The maximum amount of virtual memory available to the process
    {
      domain = "*";
      type = "-";
      item = "as";
      value = "unlimited";
    }
    # The maximum number of file locks
    {
      domain = "*";
      type = "-";
      item = "locks";
      value = "unlimited";
    }
  ];

  system.autoUpgrade = lib.mkIf (flakeRef != null) {
    enable = lib.mkDefault true;
    flake = lib.mkDefault flakeRef;
    flags = lib.mkDefault ["--show-trace"];
    dates = lib.mkDefault "weekly";
    allowReboot = lib.mkDefault false;
  };

  # NixOS 默认启用的是 systemd-timesyncd，这是 systemd 自带的一个轻量 SNTP（简化版 NTP）客户端，用来自动同步时间。NixOS 的 NTP 文档里明确说默认 NTP 实现是 systemd-timesyncd。
  # https://mynixos.com/nixpkgs/options/services.chrony

  # 想让这台机器 给别的机器当时间服务器（NTP/NTS server）
  #对时间精度有比较高的要求（日志对齐、多机事务、金融、监控等）：需要 毫秒甚至更优
  #机器 经常睡眠/断网/虚拟化环境多，网络质量比较复杂
  # ➜ 更推荐 chrony：功能更强、精度更高、对「不稳定环境」适配更好。
  # 「懒得折腾 + 一般用途」：留在 NixOS 默认的 systemd-timesyncd ✅
  #「要精度、要 NTS、要当时间服务器」：换到 chrony ✅
  services.timesyncd.enable = lib.mkDefault true;
}
