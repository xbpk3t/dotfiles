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
    };

    devops = {
      helix.enable = true;
      rclone.enable = false;
      hunk.enable = false;
      ssh.enable = false;

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
    };
  };

  # VPS 上 Caddy 管理 edge 网络，所有服务都需要以 external 方式加入。
  home.sessionVariables.EDGE_NETWORK_EXTERNAL = "true";
}
