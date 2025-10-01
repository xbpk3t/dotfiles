{
  lib,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      bash-completion
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
    # PLAN 之后可能会同时enable zsh和bash，再做个对比，暂时不开启
    zsh.enable = false;
    bash = {
      enable = true;

      # 禁用 bash completion 以提升性能（对应 zsh 的 enableCompletion = false）
      enableCompletion = true;

      # 历史记录配置
      # 使用默认的 bash 历史设置，不启用 Atuin（保持简单和快速）
      historySize = 10000; # 内存中保存的历史条数
      historyFileSize = 10000; # 文件中保存的历史条数
      historyControl = ["ignoredups"]; # 忽略重复命令
      historyIgnore = [
        "ls"
        "cd"
        "pwd"
        "exit"
        "history"
        "__jetbrains_intellij_run_generator.*"
      ];

      shellAliases = {
        # 目录导航
        # 注意：bash 不支持 "-" 作为别名，使用函数替代
        "..." = "../..";
        "...." = "../../..";
        "....." = "../../../..";
        "......" = "../../../../..";
        # 注意：bash 不支持 zsh 的 cd -1, cd -2 等数字历史导航

        # 权限和基础命令
        "_" = "sudo ";
        "c" = "clear";

        # 现代工具替代
        "cat" = "bat";
        "find" = "fd --hidden"; # 使用 fd 替代 find，显示隐藏文件
        "grep" = "rg";

        # 文件操作
        ll = "eza -la";
        la = "eza -a";
        lls = "eza -la --sort=size --reverse --total-size";
        "md" = "mkdir -p";
        "rd" = "rmdir";

        # 编辑器
        "vim" = "LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 nvim";
      };

      # bash 的 shell 选项设置（性能优化）
      shellOptions = [
        # 历史相关选项
        "histappend" # 追加历史而不是覆盖
        "histverify" # 历史展开时先验证

        # 性能和便利性选项
        "checkwinsize" # 检查窗口大小变化
        "cdspell" # 自动纠正 cd 的拼写错误
        "autocd" # 启用自动 cd 功能（直接输入目录名进入）
        # "dirspell"      # 这个选项在某些 bash 版本中不存在，注释掉

        # 其他选项
        # "globstar"      # 不启用 ** glob

        "nocaseglob" # 处理忽略大小写的通配符（例如， cat read* ）
      ];

      # 初始化配置（对应 zsh 的 initContent）
      initExtra = ''
        # ===== Locale 设置 =====
        # 使用推荐的最小集合，避免 LC_ALL 覆盖导致的异常
        unset LC_ALL
        export LANG=en_US.UTF-8
        export LC_CTYPE=en_US.UTF-8
        # 使用 C 排序避免找不到本地化定义
        export LC_COLLATE=C

        # ===== Bash 性能优化设置 =====
        # 禁用可能慢的 completion 功能
        # complete -r  # 清除所有 completion 定义



        # 设置更快的 PS1 prompt（简单高效）
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

        # 优化历史设置
        HISTCONTROL=ignoreboth:erasedups
        HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

        # ===== 函数定义 =====
        # 替代 zsh 的 cd - 功能
        cd() {
          if [[ "$1" == "-" ]]; then
            builtin cd -
          else
            builtin cd "$@"
          fi
        }

        # mkcd 函数：创建目录并进入
        mkcd() {
          if [[ $# -eq 0 ]]; then
            echo "Usage: mkcd <directory>"
            return 1
          fi
          mkdir -p "$1" && cd "$1"
        }

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
        # 启用 vi 模式（对应 zsh 的 defaultKeymap = "viins"）
        set -o vi

        # 启用不区分大小写的制表符补全。跟 nocaseglob 搭配使用。
        bind 'set completion-ignore-case on'

        # ===== 文件后缀处理 =====
        # Bash 不直接支持 zsh 的 alias -s 功能
        # 如果需要类似功能，可以通过函数实现
        # 注释掉以提升启动性能，如果需要可以手动启用
        # open_with_goland() {
        #   case "$1" in
        #     *.md|*.go|*.json|*.ts|*.html|*.yaml|*.yml|*.py|*.sql)
        #       goland "$1" ;;
        #     *)
        #       echo "Unsupported file type" ;;
        #   esac
        # }

        # ===== 性能优化 =====
        # 减少不必要的路径扫描
        unset MAILCHECK  # 禁用邮件检查
      '';

      # 登录时执行的额外命令（对应 zsh 的 loginExtra）
      profileExtra = ''
        # 加载 Nix 环境（如果需要）
        if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
          source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        fi
      '';

      # bash 退出时执行的命令
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
      enableBashIntegration = true;
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
      enableBashIntegration = true;
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

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      # 使用提供的 starship.toml 配置
      settings = {
        # Get editor completions based on the config schema
        "$schema" = "https://starship.rs/config-schema.json";

        right_format = "$cmd_duration$env_var";

        # Inserts a blank line between shell prompts
        add_newline = true;

        # Replace the '❯' symbol in the prompt with '➜'
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
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

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
