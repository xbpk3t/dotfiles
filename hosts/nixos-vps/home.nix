{...}: {
  modules.infra = {
    nh.enable = true;
    networking.enable = true;
  };

  modules.extra = {
    zed-remote.enable = true;
  };

  # VPS 上 Caddy 管理 edge 网络，所有服务都需要以 external 方式加入
  home.sessionVariables.EDGE_NETWORK_EXTERNAL = "true";
}
