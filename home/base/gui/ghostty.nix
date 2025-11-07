_: {
  # https://mynixos.com/home-manager/options/programs.ghostty
  # https://mynixos.com/nixpkgs/package/ghostty
  programs.ghostty = {
    enable = true;
    #package = pkgs.ghostty;

    installVimSyntax = true;
    installBatSyntax = true;
    enableZshIntegration = true;

    settings = {
      scrollback-limit = 10000;
      #NOTE(ghostty): not using ghostty for splits or tabs so nearly all default binds conflict Hypr, nvim, or zellij

      confirm-close-surface = false;
      background-opacity = 0.8;
      window-padding-x = 4;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste = "allow";
      copy-on-select = "clipboard";

      # background = "black";
      # window-padding-color = "background";
      # font-family = "0xProto";
      # font-size = 10;
      # mouse-hide-while-typing = true;
      # auto-update = "off";
      # gtk-titlebar = false;
      # shell-integration = "none";
      # linux-cgroup = "always";
      # resize-overlay = "never";

      keybind = [
        "ctrl+shift+d=inspector:toggle"
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        # Fix fixterm conflict with zsh ^[ character https://github.com/ghostty-org/ghostty/discussions/5071
        "ctrl+left_bracket=text:\\x1b"
        "ctrl+shift+minus=decrease_font_size:1"
        "ctrl+shift+plus=increase_font_size:1"
        "ctrl+shift+0=reset_font_size"
        #
        # ========== UNBIND ==========
        #
        "ctrl+shift+e=unbind" # new_split
        "ctrl+shift+n=unbind" # new_window
        "ctrl+shift+t=unbind" # new_tab
      ];
    };
  };
}
