# Fleet topology registry.
#
# 这里只放“其他机器需要知道”的事实：地址、tailnet IP、发布的 singbox
# 能力、Nezha hub 标记、SSH 连接策略。
#
# 单机身份/配置（user/time/editor、stateVersion、derpDomain、acmeEmail、
# hardware profile 等）应放在 hosts/<name>/ 或 flake globals 里，
# 不要再回流到这个文件。
{
  nixos-avf = {
    nixos-avf = {
      hostName = "nixos-avf";
      stateVersion = "25.11";
    };
  };

  macos-ws = {
    macos-ws = {
      hostName = "macos-ws";
      stateVersion = "24.11";
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
    };
  };

  nixos-vps = {
    nixos-vps-dev = {
      hostName = "nixos-vps-dev";
      stateVersion = "24.11";
      tailscale.ip = "100.101.189.7";
      # Nezha 只允许一个 hub；agent 的 dashboard 地址从这里派生。
      nezha = {
        hub = true;
        port = 8008;
      };
      singbox = {
        label = "LA-RN";
        server = "192.129.183.26";
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

    nixos-vps-agt = {
      hostName = "nixos-vps-agt";
      stateVersion = "26.05";
      # 2026-11-14 首次 join 后 `tailscale ip -4`。
      tailscale.ip = "100.66.22.92";
      # 纯 agent 节点；hub 地址由 fleet registry 从 hub 节点派生。
      # Mac 的 ssh.nix 读取该字段；只对交互式高延迟 host opt-in。
      ssh.multiplex = true;
    };
  };
  # nixos-usb：便携 U 盘系统（GNOME desktop），跨机器即插即用。
  # 部署/代理都走 tailnet（tailscale.ip 固定，插到任意机器都能 SSH 到）。
  nixos-usb = {
    nixos-usb = {
      hostName = "nixos-usb";
      stateVersion = "24.11";
      ssh.user = "luck";
      # fleet SSH 统一寻址：ssh.nix 只认 tailscale.ip。
      tailscale.ip = "100.87.217.1";
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
    #   ssh = {
    #     host = "<公网IP>";
    #     user = "luck";               # bootstrap 建的用户
    #     opts = [ "-o" "ServerAliveInterval=30" "-o" "ServerAliveCountMax=20" ]; # 跨境 keepalive
    #   };
    # };
    # 然后：ANSIBLE_PASSWORD='<初始密码>' \
    #   ansible-playbook -i hosts/sm-vps/ansible/inventory/sm_vps.ini \
    #     hosts/sm-vps/ansible/bootstrap.yml --ask-pass
    # 之后 deploy：task nix:deploy:sm NODE=sm-vps-<名字>，验证：task nix:deploy:smoke NODE=sm-vps-<名字>
  };
}
