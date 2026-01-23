{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;
  cfg = config.modules.extra.k3s;
  role = cfg.role;
  tokenPath = config.sops.secrets.k3s_token.path;
  isServer = role == "server";
  isAgent = role == "agent";
  validRole = isServer || isAgent;
in {
  # https://mynixos.com/nixpkgs/options/services.k3s
  #
  #
  # [This homelab setup is my favorite one yet. - YouTube](https://www.youtube.com/watch?v=2yplBzPCghA)
  #
  #
  # https://github.com/longhorn/longhorn
  options.modules.extra.k3s = with lib; {
    enable = mkEnableOption "Enable k3s (server/agent)";

    role = mkOption {
      type = types.enum ["server" "agent"];
      description = "k3s role for this node";
    };

    # 这些是基础参数，默认值可用，但需要时可以覆写
    serverAddr = mkOption {
      type = types.str;
      default = "";
      description = "k3s server address for agents (Tailscale IP recommended)";
    };

    apiServerPort = mkOption {
      type = types.port;
      default = 6443;
      description = "k3s API server port for control plane";
    };

    flannelUdpPort = mkOption {
      type = types.port;
      default = 8472;
      description = "k3s flannel VXLAN UDP port";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = validRole;
        message = "k3s: role must be 'server' or 'agent'.";
      }
    ];

    services.k3s = mkMerge [
      {
        enable = true;
        inherit role;
      }
      (mkIf isServer {
        # 共享 token：由 sops 管理（k3s/token）
        agentTokenFile = tokenPath;
      })
      (mkIf isAgent {
        # agent 连接 homelab 控制面（Tailscale IP）
        tokenFile = tokenPath;
        serverAddr = cfg.serverAddr;
      })
    ];

    # k3s 基础端口放行：
    # - server：API Server 端口 + flannel UDP
    # - agent：仅 flannel UDP
    networking.firewall = mkMerge [
      (mkIf isServer {
        allowedTCPPorts = [cfg.apiServerPort];
      })
      {
        allowedUDPPorts = [cfg.flannelUdpPort];
      }
    ];
  };
}
