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
