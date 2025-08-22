{...}: {
  # Zsh shell 配置
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "sudo"
      ];
    };

    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
    };
    shellAliases = {
      # modern replacements
      cat = "bat";
      find = "fd";
      grep = "rg";
      vim = "LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 nvim";
      # zensh style aliases
      c = "clear";
    };
    # 启用zsh插件
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      # 加载 Nix 环境
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi

      # Environment variables
      ZSH_DISABLE_COMPFIX=true
      export EDITOR=nvim
      if [ -n "$TTY" ]; then
        export GPG_TTY=$(tty)
      else
        export GPG_TTY="$TTY"
      fi

      export BUN_INSTALL=$HOME/.bun

      # PNPM 全局配置
      export PNPM_HOME="$HOME/.local/share/pnpm"
      export PATH="$HOME/go/bin:$BUN_INSTALL/bin:$PNPM_HOME:$PATH"

      # SSH_AUTH_SOCK set to GPG to enable using gpgagent as the ssh agent.
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent

      # ===== 键盘绑定 =====
      bindkey -e

      # Keybindings (zensh style)
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      bindkey '^[w' kill-region

      zle_highlight+=(paste:none)

      # ===== 文件后缀别名 =====
      # 在terminal输入文件名，可以直接用指定IDE打开该文件
      alias -s md=goland
      alias -s go=goland
      alias -s json=goland
      alias -s cs=goland
      alias -s ts=goland
      alias -s html=goland
      alias -s yaml=goland
      alias -s yml=goland
      alias -s python=goland
      alias -s sql=goland
    '';

  };

  # Modern shell tools
  programs = {
    # A cat(1) clone with syntax highlighting and Git integration
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        style = "numbers,changes,header";
      };
    };

    # A simple, fast and user-friendly alternative to find
    fd = {
      enable = true;
      hidden = true;
      ignores = [".git/" "node_modules/"];
    };

    # Atuin shell history
    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        search_mode = "prefix";
        filter_mode = "global";
        style = "compact";
        inline_height = 40;
      };
    };
  };
}
