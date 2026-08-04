{
  mylib,
  config,
  ...
}:
{
  # 分发 .taskfile 目录（供 includes 解析到子 Taskfile）
  home.file.".cntr" = {
    source = mylib.relativeToRoot ".cntr";
    recursive = true;
    force = true;
  };

  home.sessionVariables = {
    DEFAULT_PASS = "$(cat ${config.sops.secrets.ME_PASS.path})";
    DEFAULT_PWGEN = "$(cat ${config.sops.secrets.ME_PWGEN.path})";
    DEFAULT_SK = "$(cat ${config.sops.secrets.ME_SK.path})";

    # 动态获取本机 tailscale IPv4，用于需要绑定 tailnet IP 的服务
    TAILSCALE_IPV4 = "$(tailscale ip -4 | head -n 1)";

    # Actions Runner: 复用 GITHUB_TOKEN（需 Administration: Write scope）
    ACTIONS_RUNNER_TOKEN = "$(cat ${config.sops.secrets.GITHUB_TOKEN.path})";

    # WUD: Docker Hub auth（防镜像 manifest 请求限流）
    DOCKER_HUB_TOKEN = "$(cat ${config.sops.secrets.DOCKER_HUB_TOKEN.path})";
  };
}
