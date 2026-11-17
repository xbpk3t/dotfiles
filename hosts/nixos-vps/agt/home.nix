{
  config,
  hostMeta,
  mylib,
  pkgs,
  ...
}:
let
  tailnetIp = hostMeta.tailscale.ip or "127.0.0.1";

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
    infra.basePackages.enable = true;

    devops = {
      basePackages.enable = true;

      helix.enable = true;

      herdr-core = {
        enable = true;
        # 4G 机器：不在重启后自动恢复屏幕/重任务，避免再次进入内存压力循环。
        settings.restore_screen = false;
      };

      cf.enable = true;
      rclone.enable = true;
      ssh = {
        enable = true;
        github.enable = true;
      };
    };

    AI = {
      claude.enable = true;
      skills.enable = true;
      dagu = {
        enable = true;
        # 只跑 scheduler；web UI 已关闭。
        web.enable = false;
        # 避开 VPS 上 axonhub 的 8090 和给 qbittorrent 预留的 8080。
        host = tailnetIp;
        port = 8081;
        schedulerPort = 8091;
      };

      dsh.enable = false;

      opencli-browser = {
        enable = true;
        # 4G 机器：Chromium 不随 session 常驻，用 OpenCLI 前手动
        # `systemctl --user start chromium-agent`，闲置省 ~430M。
        autoStart = false;
        # x11vnc 绑 tailnet，Mac 可直接用 Screen Sharing 打开 vnc://<tailnet-ip>:5900。
        bindAddress = tailnetIp;
      };

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
      };
    };

    xdg.enable = true;

    kernel = {
      basePackages.enable = true;
      gpg.enable = true;
      network.enable = true;
      ssh.enable = true;
    };

    langs = {
      basePackages.enable = true;
      golang.enable = true;
      treefmt.enable = true;
      ts.enable = true;
      markdown.enable = true;
    };
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
