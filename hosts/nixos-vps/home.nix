_: {
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
    };

    ms = {
      k8s.enable = true;
    };

    devops = {
      herdr.enable = false;
      ghui.enable = true;
      hunk.enable = true;
    };

    AI = {
      claude.enable = true;
      skills.enable = true;
      dagu = {
        enable = true;
        # 避开 VPS 上 axonhub 的 8090 和给 qbittorrent 预留的 8080。
        port = 8081;
        schedulerPort = 8091;
      };
    };
  };

  # VPS 上 Caddy 管理 edge 网络，所有服务都需要以 external 方式加入
  home.sessionVariables.EDGE_NETWORK_EXTERNAL = "true";
}
