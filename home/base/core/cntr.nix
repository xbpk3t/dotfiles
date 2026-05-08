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
    DB_PWD = "$(cat ${config.sops.secrets.ME_SK.path})";
  };
}
