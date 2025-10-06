{pkgs, ...}: {
  # Deploy shell scripts to bin directory - organized by features
  home.file.".local/bin/rofi-snippets".source = ./rofi/snippets/snippets.sh;
  home.file.".local/bin/rofi-bookmark".source = ./rofi/bookmark/bookmark.sh;

  # Deploy data files using xdg.configFile (elegant way like wezterm.nix)
  xdg.configFile = {
    "rofi/snippets/snippets.txt".source = ./rofi/snippets/snippets.txt;
    # Deploy bookmark data file
    "rofi/bookmark/bm.yml".source = ./rofi/bookmark/bm.yml;
  };

  # Main rofi configuration
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    modes = [
      "window"
      "run"
      "drun"
      #      "emoji"
      "ssh"
      "combi"
      "keys"
      "filebrowser"
    ];

    # Main rofi configuration
    extraConfig = {
      show = "combi";
      modi = "drun,filebrowser,run";
      # 设置 combi 模式的默认组合
      combi-modes = ["drun" "run" "window"];

      # Display settings
      # font = "Noto Sans CJK JP 12";
      show-icons = true;
      icon-theme = "Papirus-Dark";

      # Behavior
      cycle = false;
      disable-history = false;
      hover-select = true;
      sidebar-mode = false;
      kb-remove-char-backward = "BackSpace";
      kb-row-left = "Control+Page_Up";
      kb-row-right = "Control+Page_Down";
      kb-mode-next = "Shift+Right";
      kb-mode-previous = "Shift+Left";
      #  kb-accept-alt = "Control+Return"; # FIXME
      # kb-custom-1 = "Control+space"; # FIXME

      # Display formats
      display-drun = "\t";
      display-run = " ";
      display-window = "🪟";
      display-filebrowser = "{";
      display-combi = "";

      # Run and drun settings
      drun-match-fields = ["name" "generic" "exec" "categories" "keywords"];
      drun-display-format = "\"{name} [<span weight='light' size='small'><i>{generic}</i></span>]\"";
      run-command = "\"{cmd}\"";
      run-shell-command = "\"{terminal} -e {cmd}\"";

      # Terminal and applications
      terminal = "kitty";
      ssh-client = "ssh";

      # File browser
      filebrowser-command = "rofi-file-browser-extended";

      # Combi mode (for universal actions)
      combi-hide-mode-prefix = true;

      # Misc
      matching = "fuzzy";
      sort = true;
      sorting-method = "fzf";
      case-sensitive = false;
    };

    # Use custom spotlight theme (macOS Spotlight-like)
    # theme = "spotlight";
  };

  # Install rofi and related packages
  home.packages = with pkgs; [
    # Core rofi
    rofi

    # Essential plugins
    #  rofi-file-browser-extended
    rofi-power-menu
    rofi-calc
    # rofimoji 不需要

    # Clipboard management
    # greenclip

    # Text expansion
    espanso

    # Additional tools
    wl-clipboard
    xdotool

    # Dependencies for scripts
    gnugrep
    gnused
    coreutils
    notify-desktop
    xdg-utils
  ];
}