{
  mylib,
  config,
  ...
}: {
  # 分发 .taskfile 目录（供 includes 解析到子 Taskfile）
  home.file.".cntr" = {
    source = mylib.relativeToRoot ".cntr";
    recursive = true;
    force = true;
  };

  home.sessionVariables = {
    DEFAULT_SK = "$(cat ${config.sops.secrets.ME_SK.path})";
    TAILSCALE_IPV4 = "$(tailscale ip -4 | head -n 1)";
  };
}
