{
  config,
  myvars,
  ...
}: {
  home.file."Library/Application Support/Alfred/Alfred.alfredpreferences/workflows" = {
    # 把本地仓库里的 .alfred/workflows 直接软链到 Alfred 配置目录。
    # 说明：这里刻意用 mkOutOfStoreSymlink 确保 Alfred 可写（info.plist 会被改动），且当前不走 colmena 远程分发。
    # 如果未来需要通过 colmena 复制到远端，请改成 mylib.relativeToRoot 来让内容进入 nix store 并随部署下发。
    source = config.lib.file.mkOutOfStoreSymlink "${myvars.projectRoot}/.alfred/workflows";
    recursive = true;
    force = true;
  };
}
