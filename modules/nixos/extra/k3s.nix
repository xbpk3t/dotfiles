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
  toInt = s: builtins.fromJSON s;
  isTailnetIP = ip: let
    parts = lib.splitString "." ip;
  in
    builtins.length parts
    == 4
    && lib.elemAt parts 0 == "100"
    && (
      let
        second = toInt (lib.elemAt parts 1);
      in
        second >= 64 && second <= 127
    );
  serverAddr = "https://${cfg.serverIP}:${toString cfg.serverPort}";
  serverFlags =
    [
      "--node-ip=${cfg.serverIP}"
      "--advertise-address=${cfg.serverIP}"
      "--tls-san=${cfg.serverIP}"
      # 使用 --with-node-id 自动追加唯一 ID，避免多台同名主机冲突
      "--with-node-id"
    ]
    # 如果 serverIP 是 tailnet 段，强制 flannel 走 tailscale0，避免对外通告 LAN 地址
    ++ (lib.optional (isTailnetIP cfg.serverIP) "--flannel-iface=tailscale0");
in {
  # https://mynixos.com/nixpkgs/options/services.k3s
  #
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/README.md
  #
  #
  # [This homelab setup is my favorite one yet. - YouTube](https://www.youtube.com/watch?v=2yplBzPCghA)
  #
  #
  # https://github.com/longhorn/longhorn
  options.modules.extra.k3s = with lib; {
    enable = mkEnableOption "Enable k3s (server/agent)";

    role = mkOption {
      type = types.enum [
        "server"
        "agent"
      ];
      description = "k3s role for this node";
    };

    # 这些是基础参数，默认值可用，但需要时可以覆写
    serverIP = mkOption {
      type = types.str;
      default = "";
      description = "k3s server IP (Tailscale IP recommended)";
    };

    serverPort = mkOption {
      type = types.port;
      default = 6443;
      description = "k3s server port for agents and control plane";
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
      {
        assertion = (!isAgent) || cfg.serverIP != "";
        message = "k3s: agent requires serverIP.";
      }
      {
        assertion = (!isServer) || cfg.serverIP != "";
        message = "k3s: server requires serverIP.";
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
        extraFlags = serverFlags;
      })
      (mkIf isAgent {
        # agent 连接 homelab 控制面（Tailscale IP）
        tokenFile = tokenPath;
        serverAddr = serverAddr;
      })
    ];

    # k3s 基础端口放行：
    # - server：API Server 端口 + flannel UDP
    # - agent：仅 flannel UDP
    networking.firewall = mkMerge [
      {
        # 将 80/443 放在 k3s 模块内：只有启用 k3s 时才放行，避免未启用时暴露端口
        allowedTCPPorts = [
          80
          443
        ];
      }
      (mkIf isServer {
        allowedTCPPorts = [cfg.serverPort];
      })
      {
        allowedUDPPorts = [cfg.flannelUdpPort];
      }
    ];
  };
}
