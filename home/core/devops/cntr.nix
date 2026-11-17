{
  mylib,
  config,
  ...
}:
{
  # Compose 的运行时 env（不进 nix store）：供 task cntr:reconcile/status/diff
  # 以 `docker compose --env-file` 读取，摆脱对交互 shell sessionVariables 的依赖。
  # EDGE_NETWORK_EXTERNAL=true 与 cntr.nu 的 ensure-edge-network 配套：
  # 网络由 task 幂等创建，所有 stack 都把它当 external。
  sops.templates."cntr.env" = {
    content = ''
      DEFAULT_SK=${config.sops.placeholder.ME_SK}
      GITHUB_TOKEN=${config.sops.placeholder.GITHUB_TOKEN}
      RESEND_TOKEN=${config.sops.placeholder.RESEND_TOKEN}
      EDGE_NETWORK_EXTERNAL=true
      NINEROUTER_URL=http://9router.tailf19540.ts.net
    '';
  };

  home = {
    # 分发 .cntr 目录（供 includes 解析到子 Taskfile）
    file.".cntr" = {
      source = mylib.relativeToRoot ".cntr";
      recursive = true;
      force = true;
    };

    # sops 渲染的 compose env 软链到稳定路径，供 cntr.nu 自动发现。
    file.".config/cntr/env" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates."cntr.env".path;
    };

    sessionVariables = {
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
  };
}
