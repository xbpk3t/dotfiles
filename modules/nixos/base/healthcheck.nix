#{
#  config,
#  lib,
#  pkgs,
#  ...
#}: let
#  inherit (lib) mkIf mkDefault escapeShellArg;
#  cfg = config.services.healthchecks;
#
#  # 固定化默认值，避免在业务层反复配置。
#  dataDir = "/var/lib/healthchecks";
#  listenAddress = "127.0.0.1";
#  port = 8000;
#  pingEndpoint = "http://127.0.0.1:8000/ping/";
#  allowedHosts = ["127.0.0.1" "localhost"];
#  secretKeyFile = "${dataDir}/secret_key";
#  dataDirEsc = escapeShellArg dataDir;
#  secretFileEsc = escapeShellArg secretKeyFile;
#  userEsc = escapeShellArg cfg.user;
#  groupEsc = escapeShellArg cfg.group;
#
#  hcPing = pkgs.writeShellApplication {
#    name = "hc-ping";
#    runtimeInputs = [pkgs.curl];
#    text = ''
#      set -euo pipefail
#
#      if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
#        echo "usage: hc-ping <check-id|ping-url> [fail]" >&2
#        exit 64
#      fi
#
#      check_id="$1"
#      status="''${2:-ok}"
#
#      case "$check_id" in
#        http://*|https://*)
#          base="''${check_id%/}"
#          ;;
#        *)
#          base="${pingEndpoint}$check_id"
#          ;;
#      esac
#
#      if [ "$status" = "fail" ]; then
#        url="$base/fail"
#      else
#        url="$base"
#      fi
#
#      ${pkgs.curl}/bin/curl -fsS --retry 2 --connect-timeout 5 "$url" >/dev/null
#    '';
#  };
#in {
#  services.healthchecks = {
#    enable = mkDefault false;
#    package = pkgs.healthchecks;
#    dataDir = dataDir;
#    listenAddress = listenAddress;
#    port = port;
#    settings = {
#      DB = "sqlite";
#      SECRET_KEY_FILE = secretKeyFile;
#      ALLOWED_HOSTS = allowedHosts;
#      REGISTRATION_OPEN = false;
#      PING_ENDPOINT = pingEndpoint;
#    };
#  };
#
#  config = mkIf cfg.enable {
#    environment.systemPackages = [hcPing];
#
#    systemd.services.healthchecks-generate-secret = {
#      description = "Generate Healthchecks SECRET_KEY";
#      wantedBy = ["healthchecks.target"];
#      before = ["healthchecks-migration.service" "healthchecks.service"];
#      serviceConfig.Type = "oneshot";
#      script = ''
#        set -euo pipefail
#
#        if [ ! -s ${secretFileEsc} ]; then
#          umask 0077
#          ${pkgs.coreutils}/bin/install -d -m 0750 -o ${userEsc} -g ${groupEsc} ${dataDirEsc}
#          ${pkgs.openssl}/bin/openssl rand -hex 64 > ${secretFileEsc}
#          ${pkgs.coreutils}/bin/chown ${userEsc}:${groupEsc} ${secretFileEsc}
#          ${pkgs.coreutils}/bin/chmod 600 ${secretFileEsc}
#        fi
#      '';
#    };
#
#    systemd.services.healthchecks-migration = {
#      wants = ["healthchecks-generate-secret.service"];
#      after = ["healthchecks-generate-secret.service"];
#    };
#
#    systemd.services."healthchecks-success@" = {
#      description = "Healthchecks success ping (%i)";
#      after = ["network-online.target"];
#      wants = ["network-online.target"];
#      serviceConfig = {
#        Type = "oneshot";
#        ExecStart = "${hcPing}/bin/hc-ping %i";
#      };
#    };
#
#    systemd.services."healthchecks-fail@" = {
#      description = "Healthchecks failure ping (%i)";
#      after = ["network-online.target"];
#      wants = ["network-online.target"];
#      serviceConfig = {
#        Type = "oneshot";
#        ExecStart = "${hcPing}/bin/hc-ping %i fail";
#      };
#    };
#  };
#}
{}
