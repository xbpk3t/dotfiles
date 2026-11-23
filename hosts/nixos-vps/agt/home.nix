{
  config,
  hostMeta,
  mylib,
  pkgs,
  ...
}:
let
  tailnetIp = hostMeta.tailscale.ip;

  # 备份 agt 上的项目、未提交 WIP 和 agent 状态到 R2（restic 仓库 rclone:r2:agt-backup）。
  backupScript = pkgs.writeShellScript "restic-backup-agt" ''
    export PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/usr/bin:/bin
    exec ${pkgs.restic}/bin/restic -r rclone:r2:agt-backup backup \
      ${config.home.homeDirectory}/Desktop \
      ${config.home.homeDirectory}/.claude \
      ${config.home.homeDirectory}/.codex \
      ${config.home.homeDirectory}/.config/opencode \
      --password-file ${config.sops.secrets.RESTIC_PASSWORD.path} \
      --exclude .git --exclude node_modules \
      --exclude dist --exclude public --exclude .DS_Store --tag agt
  '';
in
{
  imports = [
    ../home.nix
  ]
  ++ map mylib.relativeToRoot [
    "home/base"
    "home/nixos"
  ];

  modules = {
    infra = {
      basePackages.enable = true;
      android.enable = true;
    };

    devops = {
      basePackages.enable = true;
      cicd.enable = true;
      distrobox.enable = true;
      yazi.enable = true;
      fetch = {
        enable = true;
        driver = "microfetch";
      };

      helix.enable = true;

      herdr-core = {
        enable = true;
        # 4G 机器：不在重启后自动恢复屏幕/重任务，避免再次进入内存压力循环。
        settings.restore_screen = false;
      };

      cf.enable = true;
      rclone.enable = true;
      tf = {
        enable = true;
        opentofu.enable = true;
        terramate.enable = true;
        lint.enable = true;
        ansible.enable = true;
      };
      ssh = {
        enable = true;
        github.enable = true;
      };
    };

    AI = {
      apm.enable = true;

      # agt 是无人值守 agent 机：开 bypassPermissions，不再逐条确认。
      # 风险边界：sudo 仍需密码（无法提权），restic 每日备份 Desktop + agent state。
      claude = {
        enable = true;
        permissionMode = "yolo";
      };
      skills.enable = true;

      # 4G agent：把三个本地 stdio MCP 换成 hosted HTTP，保留工具但省掉
      # ~214M/会话的本地进程。默认仍是 stdio，其他 host 不受影响。
      mcp.httpServers = [
        "github"
        "context7"
        "tavily"
      ];
      dagu = {
        enable = true;
        # 只跑 scheduler；web UI 已关闭。
        web.enable = false;
        # 避开 VPS 上 axonhub 的 8090 和给 qbittorrent 预留的 8080。
        host = tailnetIp;
        port = 8081;
        schedulerPort = 8091;
        # 4G 机器：DAG 步骤是 scheduler 的子进程，同样受这个 service cgroup
        # 限制；scheduler 自身稳态约 127M，但 claude -p / wiki:digest 等步骤
        # 可达数百 MB。上限按步骤峰值给，而不是只按 scheduler 稳态。
        memoryHigh = "1000M";
        memoryMax = "1500M";
      };

      dsh.enable = false;

      # opencli-browser（Xvfb/chromium-agent/x11vnc）已按 B 方案移除：
      # 4G 内存跑不动 browser + 并行 digest，浏览器相关 DAG 迁到 macos-ws。
      # 模块文件保留在 git 历史/未来 headless 需求时再恢复。

      # opencode CLI 保留；web UI 已关闭。bind/port 保留，方便以后恢复。
      opencode = {
        enable = false;
        web = {
          enable = false;
          bindAddress = tailnetIp;
          port = 4096;
        };
      };

      # CloudCLI（Claude Code UI）：只绑 tailnet IP，应用自带登录。
      cloudcli = {
        enable = true;
        bindAddress = tailnetIp;
        port = 3001;
        # 4G 机器：server 稳态 ~66M，但它拉起的 Claude Code 会话和首次
        # npm install（~1.5G）都是子进程，同样受这个 cgroup 限制。
        # MemoryHigh 是软限，给到 burst 量级；硬保护交给 user.slice 上限。
        memoryHigh = "1500M";
      };
    };

    xdg.enable = true;

    kernel = {
      basePackages.enable = true;
      disk.enable = true;
      BPF.enable = true;
      gpg.enable = true;
      network.enable = true;
      ssh.enable = true;
    };

    langs = {
      basePackages.enable = true;
      golang = {
        enable = true;
        gotools.enable = true;
      };
      python.enable = true;
      rust.enable = true;
      treefmt.enable = true;
      ts.enable = true;
      markdown.enable = true;
    };

    ms = {
      gateway = {
        enable = true;
        grpc.enable = true;
      };
      helm.enable = true;
    };

    sys.basePackages.enable = true;

    works = {
      crawler.enable = true;
      recon.enable = true;
      test.enable = true;
    };

    zzz.enable = true;
  };

  # Restic 备份：Desktop + agent state → R2。
  home.packages = [ pkgs.restic ];

  systemd.user.services.restic-backup = {
    Unit = {
      Description = "Restic backup of Desktop + agent state to R2";
      After = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${backupScript}";
    };
  };

  systemd.user.timers.restic-backup = {
    Unit.Description = "Daily restic backup";
    Timer = {
      OnCalendar = "*-*-* 04:30:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # NOTE(agt proxy 2026-11-16)：刻意不在这里全局注入 HTTP(S)_PROXY。
  # 历史：这坨是从 main 合并进来的 workaround；现在 mihomo TUN 已在系统层接管流量，
  # 且 mihomo-client 已把 Meta 加进 firewall.trustedInterfaces，解决了 TUN 回包被 DROP
  # 导致的 direct 超时。全局 proxy env 反而会和 fake-IP 打架（curl 的 NO_PROXY 认
  # 198.18.0.0/16，reqwest/atuin 不认），曾导致 atuin 5s connect timeout。
  # 结论：默认让 TUN 透明代理；个别工具确实需要 mixed-port 时，用该工具自己的
  # wrapper/alias 局部设置，不要污染整个 shell。容器/构建若需代理，也应在对应命令
  # 或 daemon 配置里显式传，而不是依赖 home.sessionVariables。
}
