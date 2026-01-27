{
  nixos-vps = {
    nixos-vps-dev = rec {
      hostName = "nixos-vps-dev";
      primaryIp = "142.171.154.61";
      hardware = {
        cpuCores = 5;
        memGiB = 6;
        bwMbps = 800;
        rttMs = 1;
      };
      k3s = {
        # What：控制面地址（server/agent 都需要）。
        # Why：所有节点统一走 tailnet，避免多网段/非对称路由导致的 flannel/CNI 不稳定。
        serverIP = "100.81.204.63";
        # What：节点自身 IP（k3s --node-ip）。
        # Why：固定为 tailscale IP，确保 Pod/Service 跨节点网络走同一张网卡。
        nodeIP = tailscale.ip;
        # What：对外可见的节点 IP（k3s --node-external-ip）。
        # Why：VPS 具备公网能力，保留 ExternalIP 便于对外展示/诊断。
        nodeExternalIP = primaryIp;
        # 业务角色（用于 node-role.kubernetes.io/<role>=true）
        roles = [ "dev" ];
        # 拓扑标签：region=NA，zone=LA
        region = "NA";
        zone = "LA";
        # 固定 node-name，避免依赖主机 hostname
        nodeName = hostName;
      };
      tailscale = {
        ip = "100.105.38.30";
        derpDomain = "derp-nixos-vps-dev.lucc.dev";
      };
      singbox = {
        label = "LA-RN";
        server = "142.171.154.61";
        port = 8443;
        hy2 = {
          domain = "hy2-nixos-vps-dev.lucc.dev";
        };
      };
    };

    nixos-vps-svc = rec {
      hostName = "nixos-vps-svc";
      primaryIp = "103.85.224.63";
      hardware = {
        cpuCores = 4;
        memGiB = 4;
        bwMbps = 18;
        rttMs = 20;
      };
      k3s = {
        # What：控制面地址（server/agent 都需要）。
        # Why：所有节点统一走 tailnet，避免多网段/非对称路由导致的 flannel/CNI 不稳定。
        serverIP = "100.81.204.63";
        # What：节点自身 IP（k3s --node-ip）。
        # Why：固定为 tailscale IP，确保 Pod/Service 跨节点网络走同一张网卡。
        nodeIP = tailscale.ip;
        # What：对外可见的节点 IP（k3s --node-external-ip）。
        # Why：VPS 具备公网能力，保留 ExternalIP 便于对外展示/诊断。
        nodeExternalIP = primaryIp;
        # 业务角色（用于 node-role.kubernetes.io/<role>=true）
        roles = [ "svc" ];
        # 拓扑标签：region=APAC，zone=HK
        region = "APAC";
        zone = "HK";
        # 固定 node-name，避免依赖主机 hostname
        nodeName = hostName;
      };
      tailscale = {
        ip = "100.74.11.67";
        derpDomain = "derp-nixos-vps-svc.lucc.dev";
      };
      singbox = {
        label = "HK-hdy";
        server = "103.85.224.63";
        port = 8443;
        hy2 = {
          domain = "hy2-nixos-vps-svc.lucc.dev";
        };
      };
    };
  };
  nixos-homelab = {
    nixos-homelab = rec {
      hostName = "nixos-homelab";
      # What：部署/连接默认地址。
      # Why：homelab 走 tailnet，避免依赖公网/NAT。
      primaryIp = "100.81.204.63";
      k3s = {
        # What：控制面地址（server/agent 都需要）。
        # Why：统一 tailnet，确保控制面与 flannel 通信稳定。
        serverIP = tailscale.ip;
        # What：节点自身 IP（k3s --node-ip）。
        # Why：固定为 tailscale IP，确保 Pod/Service 跨节点网络走同一张网卡。
        nodeIP = tailscale.ip;
        # 固定 node-name，避免依赖主机 hostname
        nodeName = hostName;
      };
      tailscale = {
        ip = "100.81.204.63";
      };
    };
  };
}
