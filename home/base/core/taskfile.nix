{
  config,
  pkgs,
  myvars,
  ...
}: {
  # 使用 mkOutOfStoreSymlink 创建指向 taskfile 目录和 Taskfile.yml 文件的符号链接
  home.file."taskfile" = {
    source = config.lib.file.mkOutOfStoreSymlink "${myvars.projectRoot}/taskfile";
    recursive = true;
  };

  home.file."Taskfile.yml".source = config.lib.file.mkOutOfStoreSymlink "${myvars.projectRoot}/taskfile/Taskfile.yml";

  home.packages = with pkgs; [
    go-task
  ];
}
