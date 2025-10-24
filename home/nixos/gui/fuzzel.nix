{
  pkgs,
  config,
  myvars,
  ...
}: {
  home.packages = with pkgs; [
    raffi
  ];

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        dpi-aware = "auto";
        lines = 6;
        prompt = "> ";
        icon-theme = "Papirus-Dark"; # 确保图标显示
      };
      key-bindings = {
        cancel = "Escape Control+g";
      };
    };
  };

  #  home.file.".local/bin/fuzzel-bookmark".source = ./fuzzel/bm/bm.sh;
  #  home.file.".local/bin/fuzzel-bookmark".executable = true;
  #  xdg.dataFile."applications/fuzzel-bookmark.desktop".text = ''
  #    [Desktop Entry]
  #    Name=Bookmark
  #    Exec=fuzzel-bookmark
  #    Type=Application
  #    Icon=bookmark
  #    Categories=Utility;
  #    Comment=Open bookmarks from YAML file
  #  '';

  #    home.file."taskfile".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${myvars.projectDir}/taskfile";

  xdg.configFile."raffi/raffi.yaml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/raffi.yml";
}
