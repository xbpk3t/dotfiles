{config,myvars, ...}: {
#  home.file.".hammerspoon".source = config.lib.file.mkOutOfStoreSymlink ./.hammerspoon;

  #
  home.file.".hammerspoon".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Desktop/${myvars.name}/.hammerspoon";
  home.file.".hammerspoon".recursive = true;
}
