{
  config,
  lib,
  pkgs,
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
  flannelIfaceIP =
    if cfg.nodeIP != ""
    then cfg.nodeIP
    else cfg.serverIP;
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

    # 节点拓扑与角色标签（由 inventory 注入）
    nodeName = mkOption {
      type = types.str;
      default = "";
      description = "k3s node name (override hostname)";
    };

    nodeIP = mkOption {
      type = types.str;
      default = "";
      description = "k3s node IP (k3s --node-ip)";
    };

    nodeExternalIP = mkOption {
      type = types.str;
      default = "";
      description = "k3s node external IP (k3s --node-external-ip)";
    };

    region = mkOption {
      type = types.str;
      default = "";
      description = "k3s topology region (topology.kubernetes.io/region)";
    };

    zone = mkOption {
      type = types.str;
      default = "";
      description = "k3s topology zone (topology.kubernetes.io/zone)";
    };

    roles = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "k3s node roles (node.kubernetes.io/role-<role>=true)";
    };

    extraLabels = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "extra k3s node labels (key=value)";
    };
  };

  config = lib.mkIf cfg.enable {
    # What：为 k3s 提供 iptables/ip6tables、ipset、conntrack 工具。
    # Why：k3s/kube-proxy 需要这些二进制来下发 Service/ClusterIP 规则，否则 10.43.0.1 等 ClusterIP 不可达。
    environment.systemPackages = [
      pkgs.iptables
      pkgs.ipset
      pkgs.conntrack-tools
    ];

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
        extraFlags =
          # 固定 node-name，避免依赖主机 hostname
          (lib.optional (cfg.nodeName != "") "--node-name=${cfg.nodeName}")
          # What：固定 node-ip，确保 k3s 选择的通信地址稳定。
          # Why：多网卡环境下避免选到非 tailnet/内网地址导致跨节点不通。
          ++ (lib.optional (cfg.nodeIP != "") "--node-ip=${cfg.nodeIP}")
          # What：对外可见 IP（仅公网节点需要）。
          # Why：便于 node ExternalIP 展示与排查/对外访问。
          ++ (lib.optional (cfg.nodeExternalIP != "") "--node-external-ip=${cfg.nodeExternalIP}")
          # 标准拓扑标签：region/zone
          ++ (lib.optional (cfg.region != "") "--node-label=topology.kubernetes.io/region=${cfg.region}")
          ++ (lib.optional (cfg.zone != "") "--node-label=topology.kubernetes.io/zone=${cfg.zone}")
          # 业务角色标签：node.kubernetes.io/role-<role>=true
          # Why：kubelet 不允许通过 --node-labels 设置 node-role.kubernetes.io/*（会直接拒绝启动）。
          ++ (lib.concatMap (roleName: ["--node-label=node.kubernetes.io/role-${roleName}=true"]) cfg.roles)
          # 额外标签（需要时覆盖）
          ++ (lib.mapAttrsToList (key: value: "--node-label=${key}=${value}") cfg.extraLabels)
          # What：固定 flannel 走 tailscale0。
          # Why：tailnet 统一承载 k3s 流量，避免 flannel 选错网卡导致跨节点不通。
          ++ (lib.optional (flannelIfaceIP != "" && isTailnetIP flannelIfaceIP) "--flannel-iface=tailscale0");
      }
      (mkIf isServer {
        # 共享 token：由 sops 管理（k3s/token）
        agentTokenFile = tokenPath;
        extraFlags =
          [
            "--advertise-address=${cfg.serverIP}"
            "--tls-san=${cfg.serverIP}"
            # What：禁用 k3s 内置组件，交给 Flux 管理（避免与 HelmRelease 冲突）。
            # Why：内置 coredns/metrics-server/local-storage/traefik 会抢占同名资源，导致 HelmRelease 失败。
            "--disable=traefik,servicelb,metrics-server,local-storage"
          ]
          # What：当 nodeIP 未显式设置时，server 用 serverIP 作为 node-ip。
          # Why：保证控制面节点至少有一个可用的固定节点地址。
          ++ (lib.optional (cfg.nodeIP == "") "--node-ip=${cfg.serverIP}");
      })
      (mkIf isAgent {
        # agent 连接 homelab 控制面（Tailscale IP）
        tokenFile = tokenPath;
        serverAddr = serverAddr;
      })
    ];

    # What：补齐 cni0 的本地 PodCIDR 路由。
    # Why：少数情况下 flannel 未自动写入主路由表，导致本机无法访问本机 Pod（CoreDNS 就绪探测超时）。
    systemd.services.k3s-cni-route = {
      description = "Ensure cni0 PodCIDR route exists";
      after = ["k3s.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if ! ${pkgs.iproute2}/bin/ip link show cni0 >/dev/null 2>&1; then
          exit 0
        fi
        cidr="$(${pkgs.iproute2}/bin/ip -4 addr show cni0 | ${pkgs.gawk}/bin/awk '/inet / {print $2; exit}')"
        if [ -n "$cidr" ]; then
          net="$(CIDR="$cidr" ${pkgs.python3}/bin/python - <<'PY'
import ipaddress, os
cidr = os.environ.get("CIDR", "")
if cidr:
    print(ipaddress.ip_network(cidr, strict=False))
PY
          )"
          if [ -n "$net" ]; then
            ${pkgs.iproute2}/bin/ip route replace "$net" dev cni0
          fi
        fi
      '';
    };

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
