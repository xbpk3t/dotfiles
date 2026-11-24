# fail2ban 服务能力。
#
# NixOS 的 fail2ban 模块默认 `logtarget = SYSLOG`，所以它的自身日志进 journald，
# 不需要 `/var/log/fail2ban.log` 的 logrotate 规则。
{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.infra.fail2ban;
in
{
  options.modules.infra.fail2ban = {
    enable = lib.mkEnableOption "fail2ban";

    maxretry = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = "Number of failures before a host is banned.";
    };

    bantime = lib.mkOption {
      type = lib.types.str;
      default = "1d";
      description = "How long a host is banned.";
    };

    ignoreIP = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "127.0.0.1/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        # Tailscale CGNAT（IPv4）与 tailnet ULA（IPv6）：
        # fleet SSH 全走 tailnet，密钥配错不应把自己 ban 掉。
        "100.64.0.0/10"
        "fd7a:115c:a1e0::/48"
      ];
      description = "Addresses that fail2ban must never ban.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      inherit (cfg) maxretry bantime ignoreIP;

      jails = {
        DEFAULT.settings.findtime = "15m";

        sshd = {
          enabled = true;
          settings = {
            port = "ssh";
            inherit (cfg) maxretry bantime;
            backend = "systemd";
          };
        };
      };
    };
  };
}
