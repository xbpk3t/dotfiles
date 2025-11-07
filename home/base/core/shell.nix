{
  lib,
  pkgs,
  config,
  ...
}: {
  home = {
    packages = with pkgs; [
      zsh-completions
      trash-cli # https://github.com/andreafrancia/trash-cli
    ];

    # PLAN fzf-tab
    # https://github.com/0xtter/nixos-configuration/blob/main/home-manager/thomas.nix
    # https://www.youtube.com/watch?v=eKkFbvanlP8
    # https://github.com/Aloxaf/fzf-tab

    # 环境变量
    # Note: Dynamic variables (those using command substitution) are set in zsh initContent
    sessionVariables =
      {
        # 通用配置
        EDITOR = "nvim";
        BROWSER = "chromium-browser";
        PWGEN_SECRET = "$(cat /etc/sk/pwgen/sk)";
        GITHUB_TOKEN = "$(gh auth token)";

        MOBILE = "$(cat /etc/sk/me/mobile)";
        PASS = "$(cat /etc/sk/me/pass)";

        # GitHub API rate limit fix
        # Commented out because it causes GitHub API 401 errors
        # See: https://discourse.nixos.org/t/nix-commands-fail-github-requests-401-without-sudo/30038
        NIX_CONFIG = "access-tokens = github.com=$(gh auth token)";

        # Locale
        LANG = "en_US.UTF-8";
        #        LC_CTYPE = "en_US.UTF-8";
        #
        LC_CTYPE = "zh_CN.UTF-8";
        LC_COLLATE = "C"; # Avoids locale lookup errors
      }
      // (lib.optionalAttrs pkgs.stdenv.isLinux {
        WINEPREFIX = config.xdg.dataHome + "/wine";
        LESSHISTFILE = config.xdg.cacheHome + "/less/history";
        LESSKEY = config.xdg.configHome + "/less/lesskey";
        DELTA_PAGER = "less -R";
      })
      // (lib.optionalAttrs pkgs.stdenv.isDarwin {
        # 用来抑制 macOS 终端中显示的 "The default interactive shell is now zsh"
        BASH_SILENCE_DEPRECATION_WARNING = "1";
      });
  };

  programs = {
    zsh = {
      enable = true;
      # 自动纠错
      autocd = true;

      shellAliases = {
        #    # 搜索时包含隐藏文件
        #    rgh = "rg --hidden";
        #    # 只搜索文件名
        #    rgf = "rg --files | rg";
        #    # 搜索并显示上下文
        #    rgc = "rg -C 3";
        #    # 搜索特定文件类型
        #    rgjs = "rg -t js";
        #    rggo = "rg -t go";
        #    rgpy = "rg -t py";
        #    rgmd = "rg -t md";
        #    # 统计匹配数
        #    rgcount = "rg -c";
        #    # 只显示匹配的文件名
        #    rgfiles = "rg -l";
        ps = "procs";
        find = "fd";
        grep = "ripgrep";
      };

      history = {
        size = 10000;
        save = 10000;
        ignoreDups = true;
        ignoreSpace = true;
      };

      # 使用新的 initContent 替代 deprecated 的 initExtraBeforeCompInit 和 initExtra
      initContent = lib.mkOrder 550 ''

        # ===== 键盘绑定 =====
        # 设置键绑定模式
        bindkey -e                 # emacs 模式（默认）
        # bindkey -v              # vi 模式（如果需要）

        # 设置不区分大小写的制表符补全
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|=*' 'l:|=* r:|=*'

        # ===== 文件后缀处理 =====
        # zsh 支持 alias -s 功能
        alias -s {md,go,json,ts,html,yaml,yml,py,sql}=goland

        # ===== eza wrapper (works even without a TTY stdin) =====
        unalias ll 2>/dev/null || true
        ll() {
          if [[ $# -eq 0 ]]; then
            command eza -l .
          else
            command eza -l "$@"
          fi
        }
        if type compdef &>/dev/null; then
          compdef _eza ll 2>/dev/null
        fi

        # ===== Locale 设置 =====
        # 使用推荐的最小集合，避免 LC_ALL 覆盖导致的异常
        unset LC_ALL
        export LANG=en_US.UTF-8
        export LC_CTYPE=en_US.UTF-8
        # 使用 C 排序避免找不到本地化定义
        export LC_COLLATE=C

        # ===== zsh 性能优化设置 =====
        # 禁用可能慢的 completion 功能
        # compdef -d  # 清除所有 completion 定义

        # 优化历史设置
        export HISTCONTROL=ignoreboth:erasedups
        export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

        # ===== 函数定义 =====
        # zsh 的 cd - 功能已经内置，不需要额外函数

        # mkcd 函数：创建目录并进入
        mkcd() {
          if [[ $# -eq 0 ]]; then
            echo "Usage: mkcd <directory>"
            return 1
          fi
          mkdir -p "$1" && cd "$1"
        }

        # rm 函数：使用 trash-cli 安全删除
        rm() {
          if command -v trash-put &> /dev/null; then
            trash-put "$@"
          elif command -v trash &> /dev/null; then
            trash "$@"
          else
            echo "Error: 'trash' command not found. Please install 'trash-cli' to use safe deletion."
            return 1
          fi
        }

        # ===== 键盘绑定 (Alt 版本) =====
        bindkey -s '^[1' 'btop\n'         # Alt+1: btop
        bindkey -s '^[2' 'yazi\n'         # Alt+2: yazi
        bindkey -s '^[3' 'fastfetch\n'    # Alt+3: fastfetch
        bindkey -s '^[4' 'fzf\n'          # Alt+4: fzf
        bindkey -s '^[5' 'lazygit\n'      # Alt+5: lazygit



        # ===== 性能优化 =====
        # 减少不必要的路径扫描
        unset MAILCHECK  # 禁用邮件检查

        # ===== 其他优化 =====
        # 启用自动补全缓存
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path ~/.zsh/cache

        # 补全样式
        zstyle ':completion:*' menu select
        zstyle ':completion:*' list-colors
        zstyle ':completion:*' verbose yes
      '';

      # zsh 退出时执行的命令
      logoutExtra = ''
        # 清理临时文件或执行其他清理操作
        # 目前保持空白以最大化性能
      '';

      # PATH 设置（使用 Home Manager 的正确方式）
      # MAYBE [2025-10-06] home.sessionPath -> programs.zsh.sessionVariables 现在zsh有bug，只能这么来处理
      #  [bug: home.sessionPath is broken with ZSH · Issue #2991 · nix-community/home-manager](https://github.com/nix-community/home-manager/issues/2991)
      sessionVariables = {
        PATH = lib.concatStringsSep ":" [
          #          "$HOME/.orbstack/bin"
          "$HOME/go/bin"
          "$HOME/.bun/bin"
          "$HOME/.local/share/pnpm/bin"
          "$HOME/.local/bin" # rofi shells

          "$PATH" # 注意放到最后，且不要删除
        ];
        #        PATH = "$HOME/.orbstack/bin:$HOME/go/bin:$BUN_INSTALL/bin:$PNPM_HOME/bin:$HOME/.local/bin:$PATH";
      };
    };

    # A cat(1) clone with syntax highlighting and Git integration
    bat = {
      enable = true;
    };

    # Better ls and lsd
    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;

      icons = "auto";

      extraOptions = [
        "--group-directories-first"
        "--no-quotes"
        "--header" # Show header row
        "--git-ignore"
        "--icons=always"
        # "--time-style=long-iso" # ISO 8601 extended format for time
        "--classify" # append indicator (/, *, =, @, |)
        "--hyperlink" # make paths clickable in some terminals
      ];
    };

    # Better find
    fd = {
      enable = true;
      hidden = true;
      ignores = [".git/" "node_modules/"];
    };

    # Better grep
    ripgrep = {
      enable = true;

      # 配置参数
      arguments = [
        # 智能大小写匹配
        "--smart-case"
        # 显示行号
        "--line-number"
        # 显示列号
        "--column"
        # 不显示标题
        "--no-heading"
        # 颜色输出
        "--color=always"
        # 最大列宽（避免过长行）
        "--max-columns=300"
        # 用来 conjunction with --max-columns, 即使超出也preview前面的部分
        "--max-columns-preview"
        # 最大文件大小（避免二进制文件）
        "--max-filesize=10M"
      ];
    };

    # Atuin shell history
    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = false;
        search_mode = "prefix";
        filter_mode = "global";
        style = "compact";
        inline_height = 20;
        dialect = "us";
        timezone = "local";
        show_preview = false;
        history_filter = [
          "__jetbrains_intellij_run_generator.*"
        ];
      };
    };

    starship = {
      enable = true;

      enableZshIntegration = true;

      # 使用提供的 starship.toml 配置
      settings = {
        # Get editor completions based on the config schema
        "$schema" = "https://starship.rs/config-schema.json";

        format = lib.concatStrings [
          "$all"
          "$character"
        ];

        right_format = lib.concatStrings [
          #            "$time"
          "$cmd_duration"
        ];

        # Inserts a blank line between shell prompts
        add_newline = true;

        # Replace the '❯' symbol in the prompt with '➜'
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };

        # 开启time
        time = {
          disabled = true;
          format = " [$time]($style)"; # 前面有空格，在路径行末尾显示
          time_format = "%T"; # 24 小时制，显示小时:分钟:秒
          style = "bright-cyan";
        };

        # Disable the package module, hiding it from the prompt completely
        package = {
          disabled = true;
        };

        directory = {
          truncation_length = 0;
          truncate_to_repo = false;
          style = "bold #82AAFF";
        };

        git_branch = {
          format = "[$symbol$branch(:$remote_branch)]($style) ";
        };

        git_status = {
          style = "bold #82AAFF";
        };

        #      env_var = {
        #        all_proxy = {
        #          variable = "all_proxy";
        #          format = "[$env_value]($style) ";
        #          default = "";
        #          style = "bold #82AAFF";
        #        };
        #      };

        cmd_duration = {
          format = "[$duration]($style) ";
          min_time = 0; # 单位：ms，500ms 即 0.5 秒
          style = "bright-yellow";
        };

        hostname = {
          disabled = true;
        };

        username = {
          disabled = true;
        };

        os = {
          disabled = true;
          #        symbols = {
          #          Ubuntu = "󰕈 ";
          #        };
        };
      };
    };

    htop = {
      enable = true;
    };

    # zoxide会记录哪些command的path? 只要你用 cd、z、zi、pushd、popd 等改变目录的命令，zoxide 都会自动记录 —— 不需要你手动 zoxide add
    # zoxide的rank怎么计算? 可以理解为LRU机制（访问频率、最近访问时间。除此之外还有 path深度）

    # zoxide query --list | head -10
    # zi # 内置了fzf

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        # zoxide 默认就是用 z 作为 alias，添加参数则使用cd作为alias
        # "--cmd cd"
      ];
    };

    # 快速 tldr 客户端
    #    tealdeer = {
    #      enable = lib.mkDefault false;
    #      enableAutoUpdates = false;
    #    };
  };
}
