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

  macos-ws = {
    macos-ws = {
      hostName = "macos-ws";
      stateVersion = "24.11";
      primaryIp = "127.0.0.1";
      ssh = {
        # 部署入口：VPS 通过 tailnet 直连 Mac；本地部署仍可用 127.0.0.1。
        host = "100.87.216.84";
        # 首次连接自动记录 host key：Mac/VPS 两边发起都无需手动 ssh-keyscan。
        # tailnet 内 TOFU 可接受；host key 真变了仍会报错。
        opts = [
          "-o"
          "StrictHostKeyChecking=accept-new"
        ];
        user = "luck";
      };
      # fleet SSH 统一寻址：ssh.nix 只认 tailscale.ip。
      tailscale.ip = "100.87.216.84";

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
      role = "server";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
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

    nixos-vps-agt = rec {
      hostName = "nixos-vps-agt";
      stateVersion = "26.05";
      primaryIp = "1.15.64.188";
      acmeEmail = "yyzw@live.com";
      # agent 角色：dagu + headed Chromium/opencli + Tailscale DERP；不跑 singbox。
      role = "agent";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
      networking = {
        # 腾讯云 Lighthouse 实际默认路由网卡：ens5（2026-11-13 部署实测）。
        externalInterface = "ens5";
      };
      hardware = {
        cpuCores = 4;
        memGiB = 4;
        bwMbps = 6;
        rttMs = 30;
      };
      tailscale = {
        # 短域名：nva = nixos-vps-agt；域名里不体现 derp。
        derpDomain = "nva.lucc.dev";
        # 2026-11-14 首次 join 后 `tailscale ip -4`。
        ip = "100.66.22.92";
      };
      # Mac 的 ssh.nix 读取该字段；只对交互式高延迟 host opt-in。
      ssh.multiplex = true;
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
      # fleet SSH 统一寻址：ssh.nix 只认 tailscale.ip。
      tailscale.ip = "100.87.217.1";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
    };
  };

  # sm-vps 平行轨（非 NixOS）：system-manager + standalone HM。
  # commit scope: sm；hosts/ 角色目录: hosts/sm-vps。
  sm-vps = {
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
    # 共享机（共用 VPS；腾讯云香港 103.79.184.82）。
    # - shared = true：sm 系统侧只保留 managed-flag（其余基线全部关闭），
    #   HM 用裁剪集（不 import home/core 全量，避免 zsh/gh/cntr 引用 sops）。
    # - ssh 连接：root 密码登录起步，bootstrap 建 luck 后走 luck+key。
    sm-vps-hk = {
      hostName = "sm-vps-hk";
      stateVersion = "24.11";
      system = "x86_64-linux";
      user = commonUser;
      time = commonTime;
      editor = commonEditor;
      shared = true;
      ssh = {
        host = "103.79.184.82";
        user = "luck";
        opts = [
          "-o"
          "ServerAliveInterval=30"
          "-o"
          "ServerAliveCountMax=20"
        ];
      };
    };
    # ── 加新真机模板 ──────────────────────────────────────────────
    # sm-vps-<名字> = {
    #   hostName = "sm-vps-<名字>";   # 与节点名一致（/etc/sm-vps-managed 的 node=）
    #   stateVersion = "24.11";
    #   system = "x86_64-linux";
    #   user = commonUser;
    #   time = commonTime;
    #   editor = commonEditor;
    #   ssh = {
    #     host = "<公网IP>";
    #     user = "luck";               # bootstrap 建的用户
    #     opts = [ "-o" "ServerAliveInterval=30" "-o" "ServerAliveCountMax=20" ]; # 跨境 keepalive
    #   };
    # };
    # 然后：ROOT_PASS='<初始密码>' HOST=<IP> NODE=sm-vps-<名字> \
    #   ./hosts/sm-vps/bootstrap/phase8-real.sh
    # 之后 deploy：task nix:deploy:sm NODE=sm-vps-<名字>，验证：task nix:deploy:smoke NODE=sm-vps-<名字>
  };
}
