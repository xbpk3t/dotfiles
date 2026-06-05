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
    DEFAULT_SK = "$(cat ${config.sops.secrets.ME_SK.path})";
    TAILSCALE_IPV4 = "$(tailscale ip -4 | head -n 1)";

    # Actions Runner: 复用 GITHUB_TOKEN（需 Administration: Write scope）
    ACTIONS_RUNNER_TOKEN = "$(cat ${config.sops.secrets.GITHUB_TOKEN.path})";

    # WUD: Docker Hub auth（防镜像 manifest 请求限流）
    DOCKER_HUB_TOKEN = "$(cat ${config.sops.secrets.DOCKER_HUB_TOKEN.path})";

    # Sub-Store: 从 Gist 恢复数据（首次备份后填入 Gist raw URL + #noCache）
    SUB_STORE_DATA_URL = "https://gist.githubusercontent.com/xbpk3t/7e293127e3d58f85024bb310c9d7e645/raw/80cd32b36afe0a869b468d5bdaf7b66e8e2ee745/Sub-Store#noCache";
    # Sub-Store: 备份/同步状态推送（Bark/Telegram/ServerChan）
    # SUB_STORE_PUSH_SERVICE = "";
  };
}
