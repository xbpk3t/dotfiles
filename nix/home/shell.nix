_: {
  # Zsh shell 配置
  programs.zsh = {
    enable = true;

    # 移除 oh-my-zsh，使用原生 zsh 功能
    # oh-my-zsh = {
    #   enable = false;
    # };

    # 使用 Atuin 管理历史记录，注释掉原生 zsh history 配置
    # history = {
    #   size = 10000;
    #   save = 10000;
    #   path = "$HOME/.zsh_history";
    #   ignoreDups = true;
    #   share = true;
    # };

    # 基于 alias.md 的别名配置
    shellAliases = {
      # 目录导航
      "-" = "cd -";
      "..." = "../..";
      "...." = "../../..";
      "....." = "../../../..";
      "......" = "../../../../..";
      "1" = "cd -1";
      "2" = "cd -2";
      "3" = "cd -3";
      "4" = "cd -4";
      "5" = "cd -5";
      "6" = "cd -6";
      "7" = "cd -7";
      "8" = "cd -8";
      "9" = "cd -9";

      # 权限和基础命令
      "_" = "sudo ";
      "c" = "clear";

      # 现代工具替代
      "cat" = "bat";
      "find" = "fd --hidden";  # 使用 fd 替代 find，显示隐藏文件
      "grep" = "rg";

      # 文件操作
      "l" = "ls -lah";
      "la" = "ls -lAh";
      "ll" = "ls -lh";
      "ls" = "ls -G";
      "lsa" = "ls -lah";
      "md" = "mkdir -p";
      "rd" = "rmdir";

      # 编辑器
      "vim" = "LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 nvim";

      # 系统工具
      "run-help" = "man";
      "which-command" = "whence";

      # grep 变体
      "egrep" = "grep -E";
      "fgrep" = "grep -F";
    };

    # 启用zsh插件
    autosuggestion.enable = false;
    enableCompletion = false;
    syntaxHighlighting.enable = true;

    # 环境变量（替代 initContent 中的 export）
    sessionVariables = {
      EDITOR = "nvim";
      BUN_INSTALL = "$HOME/.bun";
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };

    # 路径设置
    profileExtra = ''
      # 添加到 PATH
      export PATH="$HOME/go/bin:$BUN_INSTALL/bin:$PNPM_HOME:$PATH"
    '';

    # 登录时执行（替代部分 initContent）
    loginExtra = ''
      # 加载 Nix 环境
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '';

    # 本地变量设置
    localVariables = {
      # GPG TTY 设置
      GPG_TTY = "$(tty)";
    };

    # 键盘绑定（替代 initContent 中的 bindkey）
    defaultKeymap = "emacs";  # 等同于 bindkey -e

    # 历史记录设置（如果不用 Atuin 的话）
    historySubstringSearch = {
      enable = true;
      searchUpKey = "^p";
      searchDownKey = "^n";
    };

    # 原生 zsh 插件配置
    # plugins = [
    #   {
    #     name = "zsh-git-prompt";
    #     src = builtins.fetchGit {
    #       url = "https://github.com/olivierverdier/zsh-git-prompt";
    #       rev = "master";
    #     };
    #   }
    # ];

    # 初始化配置（使用新的属性名 initContent）
    initContent = ''
      # GPG TTY 动态设置
      if [ -n "$TTY" ]; then
        export GPG_TTY=$(tty)
      else
        export GPG_TTY="$TTY"
      fi

      # 自定义键盘绑定
      bindkey '^[w' kill-region

      # 粘贴高亮设置
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

      # sudo 插件功能（ESC ESC 添加 sudo）
      sudo-command-line() {
          [[ -z $BUFFER ]] && zle up-history
          if [[ $BUFFER == sudo\ * ]]; then
              LBUFFER="${LBUFFER#sudo }"
          else
              LBUFFER="sudo $LBUFFER"
          fi
      }
      zle -N sudo-command-line
      # 双击 ESC 添加/移除 sudo
      bindkey "\e\e" sudo-command-line
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
        dialect = "us"; # date format used, either "us" or "uk"
        timezone = "local";
        show_preview = true;
        history_filter = [
          "__jetbrains_intellij_run_generator.*"
        ];
      };
    };
  };
}
