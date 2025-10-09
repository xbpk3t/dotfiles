{pkgs, ...}: {
  # fzf - command-line fuzzy finder
  programs.fzf = {
    enable = true;

    # Shell integrations
    enableZshIntegration = true;

    # Use the latest fzf package
    package = pkgs.fzf;

    # Default command for finding files
    defaultCommand = "fd --type f --hidden --follow --exclude .git --exclude node_modules";

    # Default options for fzf - keep it simple
    #  defaultOptions = [
    #    "--height=40%"
    #    "--layout=reverse"
    #    "--border"
    #    "--cycle"
    #    "--multi"
    #  ];

    defaultOptions = [
      "--margin=1"
      "--layout=reverse"
      "--border=none"
      "--info='hidden'"
      "--header=''"
      "--prompt='/ '"
      "-i"
      "--no-bold"
      "--bind='enter:execute(nvim {})'"
      "--preview='bat --style=numbers --color=always --line-range :500 {}'"
      "--preview-window=right:60%:wrap"
    ];

    # File widget (CTRL-T) configuration
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git --exclude node_modules";

    # Directory widget (ALT-C) configuration
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git --exclude node_modules";

    # History widget (CTRL-R) configuration
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];

    # Tmux integration
    tmux = {
      enableShellIntegration = true;
      shellIntegrationOptions = [
        "-d40%"
        "-m"
      ];
    };

    # Note: Colors are now managed by Stylix
    # Remove manual color configuration to let Stylix handle them
  };
}
