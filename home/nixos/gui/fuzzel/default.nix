{
  pkgs,
  config,
  myvars,
  ...
}: {
  home.packages = with pkgs; [
    raffi
    cliphist
    wl-clipboard
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

  #  home.file.".local/bin/raffi-bookmark" = {
  #    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi-bookmark.nu";
  #    executable = true;
  #  };
  #
  #  home.file.".local/bin/raffi-pwgen" = {
  #    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi-pwgen.nu";
  #    executable = true;
  #  };
  #
  #  home.file.".local/bin/raffi-snippet" = {
  #    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi-snippet.nu";
  #    executable = true;
  #  };
  #
  #  home.file.".local/bin/raffi-gh" = {
  #    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi-gh.nu";
  #    executable = true;
  #  };
  #
  #  home.file.".local/bin/raffi-common.nu" = {
  #    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi-common.nu";
  #    executable = false;
  #  };

  home.activation.linkRaffiScripts = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/.local/bin

    ln -sf ${config.home.homeDirectory}/${myvars.projectDir}/home/nixosF/gui/fuzzel/raffi-bookmark.nu $HOME/.local/bin/raffi-bookmark
    chmod +x $HOME/.local/bin/raffi-bookmark

    ln -sf ${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi-pwgen.nu $HOME/.local/bin/raffi-pwgen
    chmod +x $HOME/.local/bin/raffi-pwgen

    ln -sf ${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi-snippet.nu $HOME/.local/bin/raffi-snippet
    chmod +x $HOME/.local/bin/raffi-snippet

    ln -sf ${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi-gh.nu $HOME/.local/bin/raffi-gh
    chmod +x $HOME/.local/bin/raffi-gh

    ln -sf ${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi-common.nu $HOME/.local/bin/raffi-common.nu
    # No chmod +x needed here
  '';

  xdg.configFile."raffi/raffi.yaml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${myvars.projectDir}/home/nixos/gui/fuzzel/raffi.yml";
}
