{mylib, ...}: {
  #  home.file.".hammerspoon".source = config.lib.file.mkOutOfStoreSymlink ./.hammerspoon;

  # 这里需要注意 mkOutOfStoreSymlink 后面如果配置为相对路径，会被hm认为是nix的一部分，会被作为 /nix/store 软链接到相应的HOME目录下。如果配置为绝对路径，会被指向到 nix store之外的可变目录
  home.file.".hammerspoon" = {
    #    source = config.lib.file.mkOutOfStoreSymlink "${myvars.projectRoot}/.hammerspoon";
    source = mylib.relativeToRoot ".hammerspoon";
    recursive = true;
    force = true;
  };
}
