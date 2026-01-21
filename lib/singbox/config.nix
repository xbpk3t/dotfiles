{
  outbounds,
  ruleSets,
  pkgs,
  clashSecret,
}: {
  # [Sing-box realip配置方案 - 开发调优 - LINUX DO](https://linux.do/t/topic/175470)
  # https://github.com/MetaCubeX/meta-rules-dat
  # [最好用的 sing-box 一键安装脚本 - 233Boy](https://233boy.com/sing-box/sing-box-script/)
  # https://linux.do/t/topic/1146113/5

  # https://github.com/shuritch/nixos/blob/main/src/modules/core/services/other/sing-box.nix
  # https://github.com/nukdokplex/ncaa/blob/master/nixos-modules/sing-box-client.nix
  # https://github.com/ourgal/snowfall/blob/main/lib/sing-box/default.nix
  # https://github.com/kaseiwang/flakes/blob/master/nixos/n3160/networking.nix#L294

  # 注意
  # 1、未配置
  ## certificate (若需要屏蔽某些 CA 或使用 Mozilla/Chrome 根证书列表，可显式配置。不配置时使用系统证书存储。)
  ## endpoints (通常用于 WireGuard/Tailscale 等系统接口。未使用即可保持为空。)
  # 在mac里调试singbox的几个核心命令（注意mac下systemd不会自动restart）
  ## rebuild 生成新的 config.json
  ## sudo launchctl kickstart -k "system/local.singbox.tun" # 注意 -k 强制重启 launchd 服务（会杀掉旧进程）。否则有可能无法加载最新配置
  # 另外一个注意项：注意 extraOutbounds，之所以需要外部可用节点（而非完全自建），就是因为我使用批量部署时，
  # 如果 singbox-server.nix 配置有问题，会导致本地网络直接挂掉且不易排查。此时若有外部可用节点，
  # 可以先切换到外部节点，再结合 singbox client/server 排查问题，会更高效。

  # https://sing-box.sagernet.org/configuration/log/
  log = {
    # 开启便于debug
    disabled = false;
    # 设置为warn，防止日志喷涌. 改为info
    level = "info";
    # 注意这个log path跟systemd本身生成的log（$HOME/Library/Logs/sing-box.log）不是一码事。如果不设置这个path，systemd生成的日志没有timestamp，很难排查问题
    output = "/tmp/singbox.log";
    timestamp = true;
  };

  dns = import ./dns.nix;
  # route.nix only accepts ruleSets; keep args aligned to avoid eval errors
  route = import ./route.nix {inherit ruleSets;};
  outbounds = outbounds;

  # https://sing-box.sagernet.org/configuration/inbound/
  inbounds = [
    {
      address = [
        "172.19.0.1/30"
        "fdfe:dcba:9876::1/126"
      ];
      auto_route = true;
      endpoint_independent_nat = true;
      mtu = 9000;
      strict_route = true;
      tag = "tun-in";
      type = "tun";
    }
    {
      listen = "127.0.0.1";
      listen_port = 2333;
      tag = "socks-in";
      type = "socks";
      users = [
      ];
    }
    {
      listen = "127.0.0.1";
      listen_port = 2334;
      tag = "mixed-in";
      type = "mixed";
      users = [
      ];
    }
  ];

  # https://sing-box.sagernet.org/configuration/experimental/
  experimental = {
    # 运行时持久化/缓存。可减轻 DNS/路由重建开销
    # 可缓存 rule-set 与 fakeip，重启更稳定（比如说如果设置为false，那么每次启动singbox，都会重新拉取rule-set，如果拉取失败，服务本身就起不来）
    cache_file = {
      enabled = true;
      store_fakeip = true;
      store_rdrc = true;

      # [2026-01-09] 注意为了兼容NixOS，要写 /var/lib/sing-box/cache.db，因为services.sing-box 只保证创建了 /var/lib/sing-box（StateDirectory/WorkingDirectory）。所以如果写其他path，如果我们不去patch这个services，这个自定义path的 cache.db 是无法创建的，所以无法启动
      # path = "/var/cache/sing-box/cache.db";
      path = "/var/lib/sing-box/cache.db";
    };
    clash_api = {
      external_controller = "0.0.0.0:9090";
      # Clash API 若监听在 0.0.0.0，官方强烈要求设置 secret
      secret = clashSecret;
      # https://github.com/MetaCubeX/metacubexd
      # https://mynixos.com/nixpkgs/package/metacubexd
      # https://mynixos.com/nixpkgs/package/zashboard
      # 'zashboard' has been removed because upstream repository
      external_ui = pkgs.metacubexd;
    };
  };

  # 未配置即默认禁用；可在系统时间不可靠时提供时间同步服务
  ntp = {
    enabled = false;
    server = "time.apple.com";
    server_port = 123;
    interval = "30m";
  };

  # https://sing-box.sagernet.org/configuration/service/
  services = [];
}
