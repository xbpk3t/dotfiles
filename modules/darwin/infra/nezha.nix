# Nezha agent (macOS system daemon).
#
# Symmetric with modules/nixos/infra/nezha.nix:
#   - same `modules.infra.nezha.agent` options and the same fleet-derived
#     `server` address;
#   - same root-owned sops agent secret and the same read-only agent policy.
#
# Why a system LaunchDaemon instead of a per-user LaunchAgent:
#   The NixOS counterpart runs as a system service, and the upstream macOS
#   installer also installs a root service. A LaunchDaemon starts at boot
#   (including the login window) and does not depend on a logged-in session.
#
# The hub option is intentionally not defined here: the one `nezha.hub = true`
# node is a NixOS host, so macOS only ever runs an agent.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.infra.nezha.agent;

  # System sops templates render to /run/secrets/rendered/<name>; the daemon
  # runs as root and reads it directly, so no user-home copy is needed.
  configPath = config.sops.templates."nezha-agent-config".path;

  # sops-nix's own LaunchDaemon may not have rendered the template yet on the
  # first boot. Wait briefly instead of letting launchd restart-loop on a
  # missing config.
  launcher = pkgs.writeShellScript "nezha-agent-launcher" ''
    i=0
    while [ "$i" -lt 120 ]; do
      if [ -s ${lib.escapeShellArg configPath} ]; then
        exec ${lib.getExe pkgs.nezha-agent} -c ${lib.escapeShellArg configPath}
      fi
      sleep 2
      i=$((i + 1))
    done
    echo "nezha-agent: config not rendered after 240s: ${configPath}" >&2
    exit 1
  '';
in
{
  options.modules.infra.nezha.agent = {
    enable = lib.mkEnableOption "Nezha agent (macOS LaunchDaemon)";

    server = lib.mkOption {
      type = lib.types.str;
      example = "100.101.189.7:8008";
      description = "Nezha dashboard address (tailnet IP:port) the agent connects to.";
    };

    uuid = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Stable agent UUID. Generate once with `uuidgen` and set it in the
        host module; do not derive it from the hostname.
      '';
    };

    hardDrivePartitionAllowlist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/System/Volumes/Data" ];
      description = ''
        Mountpoints the agent reports as disks.

        macOS APFS volumes share one container, but each volume's `df` reports
        the full container size. The agent sums every reported partition, so
        without an allowlist a 256GB Mac shows roughly 7× its real capacity.
        Default to the data volume (the writable user-data volume).
      '';
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || cfg.uuid != null;
          message = "modules.infra.nezha.agent.uuid must be set by the host when the agent is enabled.";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      # Agent secret is already part of the full system secret set
      # (secrets/default.nix); the template only embeds it into the JSON config.
      sops.templates."nezha-agent-config".content = builtins.toJSON {
        inherit (cfg) server uuid;
        client_secret = config.sops.placeholder.NEZHA_AGENT_SK;
        hard_drive_partition_allowlist = cfg.hardDrivePartitionAllowlist;

        # Keep the dashboard read-only. Auto-update is off because the binary
        # lives in the read-only Nix store.
        disable_command_execute = true;
        disable_auto_update = true;
        disable_force_update = true;
        tls = false;
      };

      launchd.daemons.nezha-agent.serviceConfig = {
        Label = "local.nezha.agent";
        ProgramArguments = [ "${launcher}" ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        ProcessType = "Background";
        StandardOutPath = "/var/log/nezha-agent.log";
        StandardErrorPath = "/var/log/nezha-agent.log";
        EnvironmentVariables = {
          HOME = "/var/root";
          PATH = "/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    })
  ];
}
