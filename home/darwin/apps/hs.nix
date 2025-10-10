{config, ...}: {
  home.file.".hammerspoon".source = config.lib.file.mkOutOfStoreSymlink ./.hammerspoon;
  home.file.".hammerspoon".recursive = true;
}
