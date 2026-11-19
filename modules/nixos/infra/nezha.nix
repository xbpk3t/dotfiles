# Nezha monitoring: one hub + one agent per host.
#
# Why a module instead of raw services.* in the host:
#   - Hub and agent share the same agent secret (sops), so keeping the
#     wiring in one place avoids drift between the two hosts.
#   - The hub port is also the agent gRPC port; the firewall rule and the
#     agent `server` address must agree.
#
# Scope: the hub/agent process is declared here. The monitored host list,
# display names, groups and notification channels live in Nezha's SQLite DB
# and are configured once via the dashboard (see the deployment notes).
{
  config,
  hostMeta,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.infra.nezha;
in
{
  options.modules.infra.nezha = {
    hub = {
      enable = lib.mkEnableOption "Nezha dashboard (hub)";

      port = lib.mkOption {
        type = lib.types.port;
        default = lib.attrByPath [ "nezha" "port" ] mylib.fleet.nezha.defaultPort hostMeta;
        description = "Nezha dashboard and agent gRPC port (hostMeta.nezha.port or the fleet default).";
      };

      listenHost = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = ''
          Address the Nezha dashboard listens on.

          Keep 0.0.0.0 so the agent connection does not race tailscaled's
          interface setup; access is restricted by the tailscale0 firewall
          rule below.
        '';
      };
    };

    agent = {
      enable = lib.mkEnableOption "Nezha agent";

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
          host module; do not derive it from FQDN.
        '';
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.agent.enable || cfg.agent.uuid != null;
          message = "modules.infra.nezha.agent.uuid must be set by the host when the agent is enabled.";
        }
        {
          # hub 的监听端口和 agent 使用的 fleet.nezha.server 必须一致。
          # fleet 只读 meta，所以 host 层覆盖 hub.port 时 meta 必须同步。
          assertion =
            !cfg.hub.enable
            || cfg.hub.port == lib.attrByPath [ "nezha" "port" ] mylib.fleet.nezha.defaultPort hostMeta;
          message = "modules.infra.nezha.hub.port must match hostMeta.nezha.port (or the fleet default) so agents can dial the hub.";
        }
      ];
    }

    (lib.mkIf cfg.hub.enable {
      services.nezha = {
        enable = true;
        settings = {
          listenhost = cfg.hub.listenHost;
          listenport = cfg.hub.port;

          # Historical metrics (1d/7d/30d) need the built-in TSDB.
          # Keep the data under the hub's StateDirectory; metrics are
          # intentionally not part of the R2/SQLite backup.
          tsdb = {
            data_path = "/var/lib/nezha/tsdb";
            retention_days = 30;
            min_free_disk_space_gb = 1;
            max_memory_mb = 256;
            write_buffer_size = 512;
            write_buffer_flush_interval = 5;
          };
        };

        # Dashboard JWT signing key and the deployment-wide agent secret.
        # Both are root secrets, read by systemd via LoadCredential.
        jwtSecretFile = config.sops.secrets.NEZHA_JWT_SK.path;
        agentSecretFile = config.sops.secrets.NEZHA_AGENT_SK.path;
      };

      # Dashboard UI and agent gRPC share one port. Only the tailnet may
      # reach it; the public interface stays closed.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.hub.port ];
    })

    (lib.mkIf cfg.agent.enable {
      services.nezha-agent = {
        enable = true;
        settings = {
          inherit (cfg.agent) server uuid;

          # Keep the dashboard read-only. Remote command execution is a
          # separate ops feature; enable it deliberately if ever needed.
          disable_command_execute = true;
        };

        # UUID comes from the host config; no FQDN dependency and no runtime
        # uuidgen. Renaming a host must not create a duplicate dashboard entry.
        genUuid = false;
        clientSecretFile = config.sops.secrets.NEZHA_AGENT_SK.path;
      };
    })
  ];
}
