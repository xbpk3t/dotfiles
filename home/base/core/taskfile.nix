{
  pkgs,
  mylib,
  ...
}: {
  # 使用 mkOutOfStoreSymlink 创建指向 taskfile 目录和 Taskfile.yml 文件的符号链接
  home.file."taskfile" = {
    source = mylib.relativeToRoot ".taskfile";
    recursive = true;
    force = true;
  };

  home.file."Taskfile.yml" = {
    source = mylib.relativeToRoot ".taskfile/Taskfile.yml";
    force = true;
  };

  home.packages = with pkgs; [
    go-task
  ];
}
