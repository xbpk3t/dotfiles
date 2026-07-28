_: {
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
    };

    devops = {
      herdr.enable = true;
      ghui.enable = true;
      hunk.enable = true;
    };

    # herdr keys.command 依赖：claude pane + SessionStart hook（见 claude.nix）
    AI = {
      claude.enable = true;
      skills.enable = true;
    };
  };

  # VPS 上 Caddy 管理 edge 网络，所有服务都需要以 external 方式加入
  home.sessionVariables.EDGE_NETWORK_EXTERNAL = "true";
}
