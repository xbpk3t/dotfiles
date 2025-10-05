{pkgs, ...}: let
  # Rofi scripts for different functionalities
  rofiScripts = with pkgs; [
    # Clipboard manager script using greenclip
    #    (writeShellScriptBin "rofi-clipboard" ''
    #      #!/usr/bin/env bash
    #      ${greenclip}/bin/greenclip daemon &
    #      sleep 0.5
    #      ${greenclip}/bin/greenclip print | ${rofi}/bin/rofi -dmenu -p "Clipboard:" \
    #        -theme-str "window { width: 60%; }" \
    #        -theme-str "listview { lines: 10; }" | ${wl-clipboard}/bin/wl-copy
    #      ${coreutils}/bin/pkill greenclip
    #    '')

    # Web search script
    (writeShellScriptBin "rofi-web-search" ''
      #!/usr/bin/env bash
      engines=("Google" "DuckDuckGo" "GitHub" "Stack Overflow" "Wikipedia" "YouTube")
      selected=$(printf "%s\n" "''${engines[@]}" | ${rofi}/bin/rofi -dmenu -p "Search Engine:")

      if [[ -n "$selected" ]]; then
        query=$(${rofi}/bin/rofi -dmenu -p "Search $selected:")
        if [[ -n "$query" ]]; then
          case "$selected" in
            "Google") ${xdg-utils}/bin/xdg-open "https://www.google.com/search?q=$query" ;;
            "DuckDuckGo") ${xdg-utils}/bin/xdg-open "https://duckduckgo.com/?q=$query" ;;
            "GitHub") ${xdg-utils}/bin/xdg-open "https://github.com/search?q=$query" ;;
            "Stack Overflow") ${xdg-utils}/bin/xdg-open "https://stackoverflow.com/search?q=$query" ;;
            "Wikipedia") ${xdg-utils}/bin/xdg-open "https://en.wikipedia.org/wiki/Special:Search?search=$query" ;;
            "YouTube") ${xdg-utils}/bin/xdg-open "https://www.youtube.com/results?search_query=$query" ;;
          esac
        fi
      fi
    '')

    # Snippets script using espanso-like functionality
    (writeShellScriptBin "rofi-snippets" ''
            #!/usr/bin/env bash
            snippets_dir="$HOME/.config/rofi/snippets"
            snippets_file="$snippets_dir/snippets.txt"

            # Create snippets directory and file if they don't exist
            mkdir -p "$snippets_dir"
            if [[ ! -f "$snippets_file" ]]; then
              cat > "$snippets_file" << 'EOF'
      # Rofi Snippets - Format: trigger:text
      email:your.email@example.com
      sig:Best regards,\nYour Name
      date:$(${coreutils}/bin/date '+%Y-%m-%d')
      time:$(${coreutils}/bin/date '+%H:%M')
      code:``` \n \n ```
      link:[Link Text](URL)
      todo:- [ ] Task description
      nix:{ pkgs, ... }:\n  # Nix configuration
      EOF
            fi

            # Extract snippet triggers
            triggers=$(${gnugrep}/bin/grep -v "^#" "$snippets_file" | ${coreutils}/bin/cut -d: -f1)
            selected=$(printf "%s\n" $triggers | ${rofi}/bin/rofi -dmenu -p "Snippet:")

            if [[ -n "$selected" ]]; then
              snippet=$(${gnugrep}/bin/grep "^$selected:" "$snippets_file" | ${coreutils}/bin/cut -d: -f2-)
              # Process snippet (expand variables, newlines)
              processed_snippet=$(eval "echo \"$snippet\"" | ${gnused}/bin/sed 's/\\n/\n/g')
              echo "$processed_snippet" | ${wl-clipboard}/bin/wl-copy
              ${notify-desktop}/bin/notify-send "Snippet Copied" "Selected snippet copied to clipboard"
            fi
    '')

    # Universal actions script
    #    (writeShellScriptBin "rofi-universal-actions" ''
    #      #!/usr/bin/env bash
    #      actions=("Applications" "Run Command" "Web Search" "Clipboard History" "Snippets" "Files" "Power Menu" "System Info")
    #      selected=$(printf "%s\n" "''${actions[@]}" | ${rofi}/bin/rofi -dmenu -p "Action:")
    #
    #      case "$selected" in
    #        "Applications") ${rofi}/bin/rofi -show drun ;;
    #        "Run Command") ${rofi}/bin/rofi -show run ;;
    #        # "Web Search") ${rofi-web-search} ;;
    #        "Clipboard History") ${rofi-clipboard} ;;
    #        "Snippets") ${rofi-snippets} ;;
    #        "Files") ${rofi-file-browser-extended}/bin/rofi-file-browser ;;
    #        "Power Menu") ${rofi-power-menu}/bin/rofi-power-menu ;;
    #        "System Info")
    #          info="OS: $(${coreutils}/bin/uname -s)\nKernel: $(${coreutils}/bin/uname -r)\nUptime: $(${coreutils}/bin/uptime -p)\nMemory: $(${procps}/bin/free -h | ${gnugrep}/bin/grep Mem)"
    #          echo -e "$info" | ${rofi}/bin/rofi -dmenu -p "System Info" -no-custom ;;
    #      esac
    #    '')

    # Workflow script for automated tasks
    #    (writeShellScriptBin "rofi-workflows" ''
    #            #!/usr/bin/env bash
    #            workflows=("Development Setup" "Meeting Notes" "Quick Email" "Screenshot & Share" "Git Commit" "Project Template")
    #            selected=$(printf "%s\n" "''${workflows[@]}" | ${rofi}/bin/rofi -dmenu -p "Workflow:")
    #
    #            case "$selected" in
    #              "Development Setup")
    #                # Open terminal, editor, and browser with dev tools
    #                ${kitty}/bin/kitty &
    #                ${visual-studio-code}/bin/code &
    #                ${google-chrome}/bin/google-chrome-stable &
    #                ${notify-desktop}/bin/notify-send "Development Setup" "Environment initialized"
    #                ;;
    #              "Meeting Notes")
    #                # Create meeting notes template
    #                notes_file="$HOME/Documents/notes/meeting-$(date +%Y%m%d-%H%M%S).md"
    #                mkdir -p "$HOME/Documents/notes"
    #                cat > "$notes_file" << EOF
    #      # Meeting Notes - $(date '+%Y-%m-%d')
    #
    #      ## Attendees:
    #      -
    #      ## Agenda:
    #      -
    #      ## Discussion:
    #      -
    #      ## Action Items:
    #      - [ ]
    #      ## Next Steps:
    #      -
    #      EOF
    #                ${visual-studio-code}/bin/code "$notes_file" &
    #                ${notify-desktop}/bin/notify-send "Meeting Notes" "Created: $notes_file"
    #                ;;
    #              "Quick Email")
    #                recipient=$(${rofi}/bin/rofi -dmenu -p "To:")
    #                subject=$(${rofi}/bin/rofi -dmenu -p "Subject:")
    #                if [[ -n "$recipient" && -n "$subject" ]]; then
    #                  ${xdg-utils}/bin/xdg-open "mailto:$recipient?subject=$subject"
    #                fi
    #                ;;
    #              "Screenshot & Share")
    #                screenshot=$(${coreutils}/bin/mktemp)/screenshot-$(date +%Y%m%d-%H%M%S).png
    #                ${gnome-screenshot}/bin/gnome-screenshot -a -f "$screenshot"
    #                if [[ -f "$screenshot" ]]; then
    #                  ${notify-desktop}/bin/notify-send "Screenshot" "Saved: $screenshot"
    #                  # You can add upload functionality here
    #                fi
    #                ;;
    #              "Git Commit")
    #                message=$(${rofi}/bin/rofi -dmenu -p "Commit message:")
    #                if [[ -n "$message" ]]; then
    #                  ${git}/bin/git add .
    #                  ${git}/bin/git commit -m "$message"
    #                  ${notify-desktop}/bin/notify-send "Git" "Committed: $message"
    #                fi
    #                ;;
    #              "Project Template")
    #                project_name=$(${rofi}/bin/rofi -dmenu -p "Project name:")
    #                if [[ -n "$project_name" ]]; then
    #                  mkdir -p "$HOME/projects/$project_name"
    #                  cd "$HOME/projects/$project_name"
    #                  ${git}/bin/git init
    #                  echo "# $project_name\n\nProject description here.\n" > README.md
    #                  ${notify-desktop}/bin/notify-send "Project Created" "$project_name initialized"
    #                fi
    #                ;;
    #            esac
    #    '')
  ];
in {
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
      # 设置 combi 模式的默认组合
      combi-modes = ["drun" "run" "window"];

      # Display settings
      font = "Noto Sans CJK JP 12";
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
      display-drun = "	";
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

    # Use built-in theme
    theme = "Arc-Dark";
  };

  # Install rofi and related packages
  home.packages = with pkgs;
    [
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

      # Custom scripts
    ]
    ++ rofiScripts;

  # Greenclip configuration for clipboard history
  #  home.file.".config/greenclip.cfg".text = ''
  #    [greenclip]
  #      history_file = "~/.cache/greenclip.history"
  #      max_history_length = 50
  #      max_selection_size = 0
  #      static_history = []
  #      trim_whitespace = true
  #      use_primary_selection = false
  #      blacklisted_applications = []
  #      enable_image_support = true
  #      image_cache_directory = "/tmp/greenclip"
  #      max_image_size = 5
  #      image_cache_length = 5
  #  '';

  # Rofi snippets configuration
  home.file.".config/rofi/snippets/snippets.txt".text = ''
    # Rofi Snippets - Format: trigger:text
    # You can customize these snippets to your needs

    # Contact information
    email:your.email@example.com
    phone:+1-234-567-8900

    # Common phrases
    thanks:Thank you for your time and consideration.
    brb:Be right back.
    ttyl:Talk to you later.

    # Development
    nixpkgs:{ pkgs, ... }:\n  \n  # Configuration here\n
    import:import ./module.nix
    shell:{ pkgs ? import <nixpkgs> {} }:\npkgs.mkShell {\n  buildInputs = with pkgs; [ ];\n}

    # Meeting templates
    meeting:## Meeting Notes - $(date '+%Y-%m-%d')\n\n### Attendees:\n- \n### Agenda:\n- \n### Action Items:\n- [ ] \n\n
    agenda:1. Review previous action items\n2. Current status updates\n3. New business\n4. Next steps\n\n

    # Code snippets
    python-main:if __name__ == "__main__":\n    main()
    python-func:def function_name():\n    \"\"\"Function description.\"\"\"\n    pass
    js-console:console.log('Debug: ', );
    js-fetch:fetch('url')\n  .then(response => response.json())\n  .then(data => console.log(data))\n  .catch(error => console.error('Error:', error));

    # File paths (customize as needed)
    docs:$HOME/Documents/
    downloads:$HOME/Downloads/
    projects:$HOME/projects/

    # Quick commands
    update:sudo nix flake update && sudo nixos-rebuild switch
    clean:nix-collect-garbage -d

    # Links
    github:https://github.com/
    nixos:https://nixos.org/
    docs:https://mynixos.com/
  '';

  # Keyboard shortcuts configuration (if using Hyprland or similar)
  # This would go in your window manager configuration
  # Example for Hyprland:
  # bind = SUPER, space, exec, rofi-universal-actions
  # bind = SUPER SHIFT, space, exec, rofi-workflows
  # bind = SUPER, c, exec, rofi-clipboard
  # bind = SUPER SHIFT, c, exec, rofi-snippets
}
