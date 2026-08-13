let
  commonUser = {
    username = "luck";
    mail = "yyzw@live.com";
  };
  commonTime = {
    timeZone = "Asia/Shanghai";
  };
  commonEditor = {
    # Why: 编辑器相关配置会被 shell、git、gh、xdg、lazygit 等多个模块共同消费。
    # 把它放到 host metadata 源头层，可以和 user/time 一样由 specialArgs 统一透传，
    # 避免在 outputs/default.nix 或各模块里重复写死同一组 editor 常量。
    command = "hx";
    desktopEntry = "Helix.desktop";
    lazygitPreset = "helix";
  };
in
{
  nixos-avf = {
    nixos-avf = {
      hostName = "nixos-avf";
      stateVersion = "25.11";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
    };
  };

  nod-am = {
    nod-am = {
      hostName = "nod-am";
      # NOD release-24.05 对应 stateVersion 24.05（enum 上限，见 NOD version.nix）
      stateVersion = "24.05";
      # NOD 用户 uid/gid：必须与真机 `id nix-on-droid` 一致
      # Why: deploy-rs 远程部署会生成错误 uid，必须显式固定（issue #94）
      user = commonUser // {
        uid = 0; # TODO: 真机 `id nix-on-droid` 后填入
        gid = 0; # TODO: 真机 `id nix-on-droid` 后填入
      };
      time = commonTime;
      editor = commonEditor;
      # deploy-rs 走 tailscale IP 连接（与 nixos-vps 同模式）
      tailscale = {
        ip = "100.123.207.1";
      };
      ssh = {
        user = "nix-on-droid";
        port = 8022; # nix-on-droid sshd 默认端口
      };
    };
  };

  nixos-ws = {
    nixos-ws = {
      hostName = "nixos-ws";
      stateVersion = "24.11";
      primaryIp = "192.168.234.194";
      ssh.user = "luck";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
    };
  };

  macos-ws = {
    macos-ws = {
      hostName = "macos-ws";
      stateVersion = "24.11";
      primaryIp = "127.0.0.1";
      ssh.user = "luck";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
    };
  };

  nixos-vps = {
    nixos-vps-dev = rec {
      hostName = "nixos-vps-dev";
      stateVersion = "24.11";
      primaryIp = "192.129.183.26";
      acmeEmail = "yyzw@live.com";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
      # sm-vps 试验床：仅本节点开 Incus（I1 + P-b）。
      # enable 只装 daemon；首次 deploy 后在机上 `incus admin init --minimal`，
      # 再 launch Debian 系统容器。不要写进全局 kernel/vm.nix。
      incus.enable = true;
      networking = {
        # 目标机默认公网出口，由 `ip -o route show default` 确认为 ens3。
        externalInterface = "ens3";
      };
      hardware = {
        cpuCores = 5;
        memGiB = 6;
        bwMbps = 800;
        # LA→China 跨境链路 RTT，用于 BDP 计算 socket buffer 上限
        rttMs = 150;
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
        ip = "100.101.189.7";
        derpDomain = "derp-nixos-vps-dev.lucc.dev";
      };
      singbox = {
        label = "LA-RN";
        server = primaryIp;
        vlessPort = 8443;
        hy2 = {
          domain = "hy2-nixos-vps-dev.lucc.dev";
          port = 8500;
        };
        vmessWs = {
          domain = "vmess-nixos-vps-dev.lucc.dev";
          port = 9443;
          path = "/vmess";
        };
        tuic = {
          domain = "tuic-nixos-vps-dev.lucc.dev";
          port = 10443;
        };
        anytls = {
          domain = "anytls-nixos-vps-dev.lucc.dev";
          port = 11443;
        };
      };
    };

    nixos-vps-svc = rec {
      hostName = "nixos-vps-svc";
      stateVersion = "24.11";
      primaryIp = "103.85.224.63";
      acmeEmail = "yyzw@live.com";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
      # 与 dev 同为 virtio VPS（hosts/nixos-vps/default.nix 的 nixos-agent
      # 容器需要 externalInterface 才能配置 NAT）；真实出口确认过是 ens3。
      networking = {
        externalInterface = "ens3";
      };
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
        server = primaryIp;
        vlessPort = 8443;
        hy2 = {
          domain = "hy2-nixos-vps-svc.lucc.dev";
          port = 8500;
        };
        vmessWs = {
          domain = "vmess-nixos-vps-svc.lucc.dev";
          port = 9443;
          path = "/vmess";
        };
        tuic = {
          domain = "tuic-nixos-vps-svc.lucc.dev";
          port = 10443;
        };
        anytls = {
          domain = "anytls-nixos-vps-svc.lucc.dev";
          port = 11443;
        };
      };
    };
  };
  nixos-homelab = {
    nixos-homelab = rec {
      hostName = "nixos-homelab";
      stateVersion = "24.11";
      # What：部署/连接默认地址。
      # Why：homelab 走 tailnet，避免依赖公网/NAT。
      primaryIp = "100.81.204.63";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
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

  # nixos-usb：便携 U 盘系统（GNOME desktop），跨机器即插即用。
  # 部署/代理都走 tailnet（primaryIp 是 tailnet IP，插到任意机器都能 SSH 到）。
  nixos-usb = {
    nixos-usb = {
      hostName = "nixos-usb";
      stateVersion = "24.11";
      primaryIp = "100.87.217.1";
      ssh.user = "luck";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
    };
  };

  # sm-vps 平行轨（非 NixOS）：system-manager + standalone HM。
  # commit scope: sm；hosts/ 角色目录: hosts/sm-vps。
  # 试验床：nixos-vps-dev 上 Incus 容器（实例名仍为 linux-sm-lab，可另 rename）。
  sm-vps = {
    sm-vps-lab = {
      hostName = "sm-vps-lab";
      stateVersion = "24.11";
      system = "x86_64-linux";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
      # Phase 5：deploy-rs 目标 = Incus 容器（经宿主 nixos-vps-dev ProxyJump）。
      # - host：容器 incusbr0 内网 IP；Mac 无法直连，靠 -J 宿主转发。
      # - user：容器内 luck（与宿主同名；容器有 NOPASSWD sudo，供 sm 系统 profile 用 root 激活）。
      # - ssh.host 也可改用 lab.container 名 + ProxyJump 后由宿主 incus exec 转，
      #   但 deploy-rs 需要 nix-daemon over SSH，必须走真 IP + ssh-ng。
      ssh = {
        host = "10.87.171.92";
        user = "luck";
        # ProxyJump：Mac → nixos-vps-dev → 容器。
        # 注：宿主 luck 到容器的 SSH 仍要 luck 能 SSH 到 10.87.171.92
        #   （Phase 5 bootstrap 需先把 Mac pubkey 放进容器 authorized_keys）。
        opts = [
          "-J"
          "luck@192.129.183.26"
        ];
      };
      lab = {
        host = "nixos-vps-dev";
        # Incus 实例名（与 flake 节点名 sm-vps-lab 可不同）
        container = "linux-sm-lab";
        note = "Incus system container on nixos-vps-dev (Debian 12, PID1=systemd)";
      };
    };
    # 真机（Phase 8）：腾讯云 Debian 13 VPS，root 密码登录起步。
    # 非 NixOS 轨的「真机验证」目标——裸 distro 上走 bootstrap → Nix → HM → sm。
    # 注意：TC 云主机无 cloud-init 可用（机器已建好），走 SSH bootstrap 路径。
    sm-vps-tc = {
      hostName = "sm-vps-tc";
      stateVersion = "24.11";
      system = "x86_64-linux";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
      # bootstrap 后 SSH 目标：luck + 公网 IP（root 密码登录仅用于首次建用户）。
      # opts 直连（无 ProxyJump）；跨境链路（~207ms RTT）+ 真机 remote build 耗时长，
      # 加 ServerAlive 防 nix-daemon 构建期间 SSH 超时断连（Phase 8 实测坑）。
      ssh = {
        host = "43.156.103.43";
        user = "luck";
        opts = [
          "-o"
          "ServerAliveInterval=30"
          "-o"
          "ServerAliveCountMax=20"
        ];
      };
    };
  };
}
