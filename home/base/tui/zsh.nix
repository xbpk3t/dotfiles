{
  lib,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      zsh-completions
      trash-cli # https://github.com/andreafrancia/trash-cli
    ];

    # 环境变量
    sessionVariables =
      {
        EDITOR = "nvim";
        BROWSER = "google-chrome";
        LANG = "en_US.UTF-8";
        LC_CTYPE = "en_US.UTF-8";
        LC_COLLATE = "C"; # Avoids locale lookup errors
        BUN_INSTALL = "$HOME/.bun";
        PNPM_HOME = "$HOME/.local/share/pnpm";
      }
      // (lib.optionalAttrs pkgs.stdenv.isDarwin {
        # 用来抑制 macOS 终端中显示的 "The default interactive shell is now zsh"
        BASH_SILENCE_DEPRECATION_WARNING = "1";
      });

    # PATH 设置（使用 Home Manager 的正确方式）
    sessionPath = [
      "$HOME/.orbstack/bin"
      "$HOME/go/bin"
      "$BUN_INSTALL/bin"
      "$PNPM_HOME/bin"
    ];
  };

  programs = {
    zsh = {
      enable = true;
      # 自动纠错
      autocd = true;


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

        # ===== 键盘绑定 =====
        # 使用 bindkey 而不是 bind
        bindkey '^F' fastfetch           # Ctrl+f: fastfetch
        bindkey '^Y' yazi                # Ctrl+y: yazi
        bindkey '^G' fzf                 # Ctrl+g: fzf
        bindkey '^T' btop                # Ctrl+t: btop

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
    };

    # A cat(1) clone with syntax highlighting and Git integration
    bat = {
      enable = true;
      #      config = { # FIXME conflict with other config
      #        theme = "TwoDark";
      #        style = "numbers,changes,header";
      #      };
    };
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

        buf = {
          symbol = " ";
        };
        c = {
          symbol = " ";
        };
        directory = {
          read_only = " 󰌾";
        };
        docker_context = {
          symbol = " ";
        };
        fossil_branch = {
          symbol = " ";
        };
        git_branch = {
          symbol = " ";
        };
        golang = {
          symbol = " ";
        };
        hg_branch = {
          symbol = " ";
        };
        hostname = {
          ssh_symbol = " ";
        };
        lua = {
          symbol = " ";
        };
        memory_usage = {
          symbol = "󰍛 ";
        };
        meson = {
          symbol = "󰔷 ";
        };
        nim = {
          symbol = "󰆥 ";
        };
        nix_shell = {
          symbol = " ";
        };
        nodejs = {
          symbol = " ";
        };
        ocaml = {
          symbol = " ";
        };
        package = {
          symbol = "󰏗 ";
        };
        python = {
          symbol = " ";
        };
        rust = {
          symbol = " ";
        };
        swift = {
          symbol = " ";
        };
        zig = {
          symbol = " ";
        };

        #      rust = {
        #        format = "[$symbol($version )]($style)";
        #      };
        #
        #      nodejs = {
        #        format = "[$symbol($version )]($style)";
        #      };
        #
        #      lua = {
        #        format = "[$symbol($version )]($style)";
        #      };
        #
        #      golang = {
        #        format = "[$symbol($version )]($style)";
        #      };
        #
        #      c = {
        #        format = "[$symbol($version(-$name) )]($style)";
        #      };
        #
        #      ruby = {
        #        format = "[$symbol($version )]($style)";
        #      };
      };
    };

    htop = {
      enable = true;
    };

    #    zoxide = {
    #      enable = true;
    #      enableZshIntegration = true;
    #      options = [
    #        "--cmd cd"
    #      ];
    #    };

    # 快速 tldr 客户端
    #    tealdeer = {
    #      enable = lib.mkDefault false;
    #      enableAutoUpdates = false;
    #    };
  };

}
