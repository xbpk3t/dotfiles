{...}: {
  # Zsh shell 配置
  programs.zsh = {
    enable = true;
    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
    };
    shellAliases = {
      # 基础别名
      ll = "ls -lh";
      l = "ls -lah";
      ".." = "cd ..";
      "..." = "cd ../..";
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
      # ===== UTF-8 编码设置 =====
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8
      export LC_CTYPE=en_US.UTF-8

      # ===== 终端美化 =====
      export CLICOLOR=1
      export LSCOLORS=ExFxBxDxCxegedabagacad

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
      export PATH="$HOME/go/bin:$BUN_INSTALL/bin:$PATH"

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

      # ===== 历史记录设置 =====
      setopt INC_APPEND_HISTORY
      setopt appendhistory
      setopt sharehistory
      setopt hist_ignore_space
      setopt hist_ignore_all_dups
      setopt hist_save_no_dups
      setopt hist_ignore_dups
      setopt hist_find_no_dups
      setopt HIST_IGNORE_DUPS

      # ===== 目录操作函数 =====
      mkcd() { mkdir -p "$1" && cd "$1" }

      # ===== robbyrussell 风格提示符 =====
      # 经典 robbyrussell 样式: ➜  directory-name
      PROMPT='%F{green}➜%f  %F{cyan}%1~%f '

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
