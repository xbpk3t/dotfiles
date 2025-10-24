{pkgs, ...}: {
  # Deploy shell scripts to bin directory - organized by features
  home.file.".local/bin/rofi-pwgen".source = ./rofi/scripts/pwgen.sh;
  home.file.".local/bin/rofi-ss".source = ./rofi/scripts/ss.sh;
  home.file.".local/bin/rofi-ww".source = ./rofi/scripts/ww.sh;
  home.file.".local/bin/rofi-gh".source = ./rofi/scripts/gh.sh;

  # Make shell scripts executable
  home.file.".local/bin/rofi-pwgen".executable = true;
  home.file.".local/bin/rofi-ss".executable = true;
  home.file.".local/bin/rofi-ww".executable = true;
  home.file.".local/bin/rofi-gh".executable = true;

  # Main rofi configuration
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    modes = [
      "window"
      "run"
      "drun"
      "ssh"
      "combi"
      "keys"
      "filebrowser"
    ];

    # Main rofi configuration
    extraConfig = {
      modi = "drun,filebrowser,run,window,pwgen:~/.local/bin/rofi-pwgen,ss:~/.local/bin/rofi-ss,ww:~/.local/bin/rofi-ww,gh:~/.local/bin/rofi-gh";
      # 设置 combi 模式的默认组合
      combi-modes = ["drun,run,window,pwgen,ss,ww,gh"];
      show = "combi";

      # Display settings
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

      # Display formats
      display-drun = "\t";
      display-run = " ";
      display-window = "🪟";
      display-filebrowser = "{";
      display-combi = "";
      display-pwgen = "🔑";
      display-ss = "📋";
      display-ww = "🌐";
      display-gh = "🐙";

      # Run and drun settings
      drun-match-fields = ["name" "generic" "exec" "categories" "keywords"];
      drun-display-format = "\"{name} [<span weight='light' size='small'><i>{generic}</i></span>]\"";
      run-command = "\"{cmd}\"";
      run-shell-command = "\"{terminal} -e {cmd}\"";

      # Terminal and applications
      terminal = "alacritty";
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
  };

  # Install rofi and related packages
  home.packages = with pkgs; [
    # Core rofi
    rofi

    # Essential plugins
    rofi-power-menu
    rofi-calc

    # Clipboard management
    wl-clipboard

    # Additional tools
    xdotool

    # Dependencies for scripts
    gnugrep
    gnused
    coreutils
    notify-desktop
    xdg-utils
    gum
    yq-go
  ];
}
