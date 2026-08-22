# Darwin networking configuration
# macOS-specific network settings and optimizations
{
  lib,
  hostMeta,
  ...
}:
let
  inherit (hostMeta) hostName;
in
{
  # Basic networking configuration
  # Note: macOS networking is mostly managed through System Preferences
  # These are the available nix-darwin networking options

  # macOS-specific network optimizations
  # Most network settings are managed through System Preferences
  # Network configuration (will be overridden by host-specific settings)

  # [networking - MyNixOS](https://mynixos.com/nix-darwin/options/networking)
  networking = {
    # 主机名体系：三件套统一 sink 到 hostMeta.hostName（macos-ws）。
    # 显式声明，避免某 host override 时只改一处导致三者漂移。
    hostName = lib.mkDefault hostName;
    computerName = lib.mkDefault hostName;
    localHostName = lib.mkDefault hostName;

    # FQDN / domain：明确不设。
    # 本机 hostname -f 就是裸 hostName（macos-ws，无真实域名），且 /etc/hosts 只有 loopback。
    # 若误设 fqdn/domain，会污染解析（假域名后缀 + 影响 scutil/服务发现），故留默认。
    # fqdn = lib.mkDefault null;
    # domain = lib.mkDefault null;

    # 显式列出 nix-darwin 要托管的网络服务。
    # 当前（networksetup -listallnetworkservices）启用的仅 Wi-Fi 与 Thunderbolt Bridge；
    # 留空=让 nix-darwin 自动发现。手动列反而在接口名变化时产生失配告警，故不设。
    # knownNetworkServices = [ "Wi-Fi" "Thunderbolt Bridge" ];

    # DHCP client identifier（请求 DHCP 时向服务器声明的标识）。
    # macOS 默认以网卡 MAC 生成；不显式设 = 用默认，避免换网卡/虚拟接口时 identifier 突变。
    # dhcpClientId = null;

    # DNS 服务器列表：保持空，交给系统/路由器/TUN(mihomo) 下发。
    # 若在此 hardcode 公共 DNS，会与 mihomo fake-ip 分流的 DNS 语义冲突，故不强制。
    dns = lib.mkDefault [ ];

    # DNS search domains（默认空：无内部域名需要追加搜索后缀）。
    search = lib.mkDefault [ ];

    wakeOnLan = {
      # 关闭网络唤醒：本机无远端唤醒需求，
      # 且 WoL 依赖以太网可达，当前主力走 Wi-Fi/mihomo，开了只会发无用广播。
      enable = false;
    };

    # [Can't enable firewall via nix-darwin · Issue #1243 · nix-darwin/nix-darwin](https://github.com/nix-darwin/nix-darwin/issues/1243)
    # [networking.applicationFirewall - MyNixOS](https://mynixos.com/nix-darwin/options/networking.applicationFirewall)
    #
    # macOS 应用防火墙（socketfilterfw）。nix-darwin ≥ PR1520 支持，驱动
    # `socketfilterfw --setglobalstate on / --setstealthmode on`。
    # 默认 null 表示"不触碰该状态"，只有显式 true/false 才执行对应命令。
    # 需本机 nix-darwin lock rev 已合并该模块（4cff07d 树内已含
    # modules/networking/applicationFirewall.nix）。
    applicationFirewall = {
      enable = true; # 开启系统防火墙
      enableStealthMode = true; # 隐身模式：不响应 ICMP 探测，内网主机不可枚举到本机监听
      # blockAllIncoming = false; # 默认 allow：不拦已授权 App / 传入连接
      # allowSigned = true;       # 放行 Apple 签名 App（默认 macOS 已是）
    };
  };

  # Note: Most network preferences are managed through macOS System Preferences
  # nix-darwin has limited support for network-related system.defaults

  # Network monitoring and diagnostics
  # Most network tools are already in home-manager configuration
}
