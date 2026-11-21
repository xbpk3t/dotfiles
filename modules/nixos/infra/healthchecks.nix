# Healthchecks.io dead-man switch.
#
# Each host pings an external Healthchecks URL on a timer. If the host,
# network, or systemd fails to send the ping, Healthchecks alerts from
# outside the fleet. This covers the case where the Nezha hub itself is
# down and therefore cannot send its own alert.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.infra.healthchecks;

  pingScript = pkgs.writeShellScript "healthchecks-ping" ''
    set -eu
    url="$(cat "$CREDENTIALS_DIRECTORY/ping-url")"
    ${lib.optionalString cfg.disk.enable ''
      disk_usage="$(${pkgs.coreutils}/bin/df --output=pcent ${lib.escapeShellArg cfg.disk.path} | ${pkgs.coreutils}/bin/tail -n 1 | ${pkgs.coreutils}/bin/tr -dc '0-9')"
      if [ "$disk_usage" -ge ${toString cfg.disk.maxUsagePercent} ]; then
        exec ${pkgs.curl}/bin/curl -fsS --retry 3 --max-time 10 "$url/fail"
      fi
    ''}
    ${lib.optionalString cfg.rebootPending.enable ''
      current_kernel="$(${pkgs.findutils}/bin/find /run/current-system/kernel-modules/lib/modules -mindepth 1 -maxdepth 1 -printf '%f\\n' | ${pkgs.coreutils}/bin/head -n 1)"
      if [ "$(${pkgs.coreutils}/bin/uname -r)" != "$current_kernel" ]; then
        exec ${pkgs.curl}/bin/curl -fsS --retry 3 --max-time 10 "$url/fail"
      fi
    ''}
    ${lib.optionalString (cfg.healthUrl != null) ''
      if ! ${pkgs.curl}/bin/curl -fsS --max-time 5 --retry 2 ${lib.escapeShellArg cfg.healthUrl} >/dev/null; then
        exec ${pkgs.curl}/bin/curl -fsS --retry 3 --max-time 10 "$url/fail"
      fi
    ''}
    exec ${pkgs.curl}/bin/curl -fsS --retry 3 --max-time 10 "$url"
  '';
in
{
  options.modules.infra.healthchecks = {
    enable = lib.mkEnableOption "Healthchecks.io dead-man switch ping";

    urlFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing the Healthchecks ping URL (sops secret).";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "1min";
      description = "How often to ping Healthchecks. Keep it shorter than the check period.";
    };

    healthUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional local health URL. If it does not return 2xx, ping
        <ping-url>/fail instead of the success URL. Use this to make the
        dead-man switch reflect a local service, not just host liveness.
      '';
    };

    disk = {
      enable = lib.mkEnableOption "disk usage check";

      path = lib.mkOption {
        type = lib.types.str;
        default = "/";
        description = "Filesystem path whose usage is checked.";
      };

      maxUsagePercent = lib.mkOption {
        type = lib.types.addCheck lib.types.ints.positive (n: n <= 100);
        default = 85;
        description = ''
          Fail the Healthchecks ping when this path's usage is at or above
          this percentage.
        '';
      };
    };

    rebootPending = {
      enable = lib.mkEnableOption "reboot-pending check";

      # 运行时内核和当前 generation 的内核不一致时 ping /fail。比比较
      # /run/booted-system 与 /run/current-system 的 store path 更准确：
      # 同一 nixpkgs 的两次 activation 也可能产生不同 store path。
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.healthchecks-ping = {
      description = "Ping Healthchecks.io dead-man switch";
      serviceConfig = {
        Type = "oneshot";
        DynamicUser = true;
        LoadCredential = "ping-url:${cfg.urlFile}";
        ExecStart = pingScript;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
      };
    };

    systemd.timers.healthchecks-ping = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = cfg.interval;
        Persistent = true;
      };
    };
  };
}
