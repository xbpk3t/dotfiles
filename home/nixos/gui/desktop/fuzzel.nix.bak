{
  pkgs,
  lib,
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

  xdg.configFile."raffi/raffi.yaml".text = lib.generators.toYAML {} {
    "firefox" = {
      binary = "firefox";
      args = ["--marionette"];
    };

    "bm" = {
      binary = "rofi-bookmark";
    };
  };
}
