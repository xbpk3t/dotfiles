{
  hostMeta,
  ...
}:
let
  tailnetIp = hostMeta.tailscale.ip or "127.0.0.1";
in
{
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
      basePackages.enable = true;
    };

    devops = {
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
}
