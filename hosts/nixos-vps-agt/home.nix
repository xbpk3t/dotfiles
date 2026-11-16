{
  config,
  hostMeta,
  pkgs,
  ...
}:
let
  tailnetIp = hostMeta.tailscale.ip or "127.0.0.1";

  proxyUrl = "http://127.0.0.1:7890";
  noProxy = "localhost,127.0.0.1,::1,100.64.0.0/10,10.0.0.0/8,192.168.0.0/16,198.18.0.0/16";

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
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
      basePackages.enable = true;
    };

    devops = {
      cf.enable = true;
      helix.enable = true;
      rclone.enable = true;
      ssh = {
        enable = true;
        github.enable = true;
      };
      herdr-core = {
        enable = true;
        settings.restore_screen = true;
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

  # agt 在 Shanghai：mihomo TUN 对部分直连不可靠，显式给 DAG/CLI 设置 mixed-port 代理。
  home.sessionVariables = {
    HTTP_PROXY = proxyUrl;
    HTTPS_PROXY = proxyUrl;
    ALL_PROXY = proxyUrl;
    NO_PROXY = noProxy;
    http_proxy = proxyUrl;
    https_proxy = proxyUrl;
    all_proxy = proxyUrl;
    no_proxy = noProxy;
  };
}
