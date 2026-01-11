{
  lib,
  pkgs,
  config,
  ...
}: {
  home = {
    packages = with pkgs; [
      zsh-completions

      # https://github.com/andreafrancia/trash-cli
      # trash-list
      # trash-empty
      trash-cli
    ];

    # PLAN 目前 fzf-tab 的使用非常麻烦（需要替代掉默认的zsh tab），等有更好的nix支持之后，再添加
    # https://github.com/0xtter/nixos-configuration/blob/main/home-manager/thomas.nix
    # https://www.youtube.com/watch?v=eKkFbvanlP8
    # https://github.com/Aloxaf/fzf-tab
    # https://mynixos.com/nixpkgs/package/zsh-fzf-tab

    # 环境变量
    # Note: Dynamic variables (those using command substitution) are set in zsh initContent
    sessionVariables =
      {
        # 通用配置
        # EDITOR = "nvim";
        # BROWSER = "chromium-browser";
        GITHUB_TOKEN = "$(gh auth token)";
        PNPM_HOME = "$HOME/.local/share/pnpm";

        # GitHub API rate limit fix
        # Commented out because it causes GitHub API 401 errors
        # See: https://discourse.nixos.org/t/nix-commands-fail-github-requests-401-without-sudo/30038
        NIX_CONFIG = "access-tokens = github.com=$(gh auth token)";

        # Locale
        LANG = "en_US.UTF-8";
        # LC_CTYPE = "en_US.UTF-8";
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
    # https://mynixos.com/home-manager/options/programs.bash
    bash = {
      enable = true;
    };

    # https://mynixos.com/home-manager/options/programs.zsh
    zsh = {
      enable = true;
      # 自动纠错
      autocd = true;

      enableCompletion = true;
      # 终端和颜色集成
      enableVteIntegration = true;
      # hm没有该配置，暂存
      # enableLsColors = true;

      # 历史管理优化
      # hm没有该配置，暂存
      # histFile = "$HOME/.zsh_history";

      # zsh 的 shell 选项设置（性能优化）
      # 性能优化配置
      # hm没有该配置，暂存
      # enableGlobalCompInit = true;

      # 为命令行着色（合法命令绿色、未知命令红色等）
      # https://mynixos.com/home-manager/options/programs.zsh.syntaxHighlighting
      # https://mynixos.com/nixpkgs/options/programs.zsh.syntaxHighlighting
      syntaxHighlighting = {
        enable = true;
        styles = {
          # 未知命令 -> 红色；其余采用默认主题
          "unknown-token" = "fg=red,bold";
        };
      };

      # 命令行自动补全/联想（zsh-autosuggestions）
      # https://mynixos.com/home-manager/options/programs.zsh.autosuggestion
      # https://mynixos.com/nixpkgs/options/programs.zsh.autosuggestions
      # 相较 modules 缺少 async
      autosuggestion = {
        enable = true;
        # 仅从历史里提示，避免与补全菜单冲突；若想更激进可加 "completion"
        strategy = ["history"];
        highlight = "fg=cyans"; # 使用暗灰色，避免喧宾夺主
      };

      # 结构化 zsh 选项配置
      setOptions = [
        # 历史相关选项
        "append_history" # 追加历史而不是覆盖
        "hist_verify" # 历史展开时先验证
        "hist_ignore_dups" # 忽略重复命令
        "hist_ignore_space" # 忽略以空格开头的命令
        "hist_no_store" # 不存储 history 命令本身

        # 性能和便利性选项
        "auto_cd" # 启用自动 cd 功能
        "correct" # 自动纠正命令拼写错误
        "cdable_vars" # 允许 cd 到变量名
        "check_jobs" # 退出时检查后台任务
        "no_case_glob" # 处理忽略大小写的通配符
        "extended_glob" # 启用扩展通配符
        "nomatch" # 如果通配符没有匹配，报错
        "notify" # 立即报告后台任务状态
        "pushd_ignore_dups" # 忽略 pushd 重复目录
        "pushd_silent" # 静默 pushd
        "auto_pushd" # 自动 pushd

        # "checkwinsize" # 检查窗口大小变化 zsh没有该项，bash的专有option
      ];

      # !!! 注意把 shellAliases 放到hm里（来复用），而非放到 modules里
      shellAliases = {
        # 目录导航
        # zsh 支持 "-" 作为别名，直接使用
        "-" = "cd -";
        "..." = "../..";
        "...." = "../../..";
        "....." = "../../../..";
        "......" = "../../../../..";
        # zsh 支持数字历史导航
        "-1" = "cd -1";
        "-2" = "cd -2";
        "-3" = "cd -3";
        "-4" = "cd -4";
        "-5" = "cd -5";

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

        # rg跟grep本身不兼容，所以不要写alias，否则每次用grep都要用 \grep
        # grep = "ripgrep";

        # TUI tool aliases
        t = "btop";
        yz = "yazi";
        ff = "fastfetch";
        lg = "lazygit";
        v = "nvim .";
      };

      # https://mynixos.com/home-manager/options/programs.zsh.history
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
        PNPM_HOME = "$HOME/.local/share/pnpm";
        PATH = lib.concatStringsSep ":" [
          #          "$HOME/.orbstack/bin"
          "$HOME/go/bin"
          "$HOME/.bun/bin"
          "$PNPM_HOME"
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
      ignores = [
        ".git/"
        "node_modules/"
      ];
    };

    # Better grep
    # 注意rg并不兼容grep（本身的用法），所以不推荐直接把grep作为rg的alias使用（否则每次都要 \grep 才能使用grep命令，很容易混淆用法）
    # 不兼容的几点：
    # - 是否递归：rg默认递归，而grep则需要 -r 才能递归查找
    # - 忽略规则：rg默认会忽略dotfiles (.git, .github, ...) 而grep不会忽略这些文件
    # - 输出格式、排序、并行：rg会并行查找，所以最终输出格式与实际文件排序无关
    # - 正则语法与选项兼容度：二者的regex引擎不同。rg默认用 Rust regex，引擎特性跟 grep 不同。而grep则默认 POSIX BRE/ERE 作为regex引擎。
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
    # https://mynixos.com/home-manager/options/programs.atuin

    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        # 多端同步是merge，而非replace
        auto_sync = true;
        # 默认30min同步，显式声明，不修改
        sync_frequency = "30m";
        # 直接使用官方服务，没必要自建
        sync_address = "https://api.atuin.sh";

        # https://wiki.nixos.org/wiki/Atuin
        # 用来在不同host之间自动sync，否则 在一台机器上注册/导入/首次同步，需要执行 atuin register 以及 atuin import auto，最后 atuin sync 手动同步。就很麻烦。
        # encryption key must be base64; session token is a UUID-like string
        # encryption key：用于加密你的本地/同步历史，必须是随机的 256‑bit 值并以 Base64 存储。
        key_path = config.sops.secrets.autin_key.path;
        # session token：登录云端 API 的“会话令牌”，通常是一个带连字符的 UUID 字符串。
        session_path = config.sops.secrets.autin_session.path;

        # 相比prefix更好用
        search_mode = "fuzzy";

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

        # 两行提示符：第一行保留 $all 的默认模块顺序；第二行显示输入符号
        format = lib.concatStrings [
          "$all"
          "\n"
          "$character"
        ];

        right_format = lib.concatStrings [
          #            "$time"
          "$cmd_duration"
        ];

        # Inserts a blank line between shell prompts
        # 我们已经在 format 里手动换行，这里关闭避免额外空行
        add_newline = false;

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
          # 路径色块：使用 bright-* 命名色，兼顾可读性与可维护性
          style = "bg:bright-blue fg:black";
          # 路径色块显示为 pill（圆角胶囊）
          format = "[](fg:bright-blue)[ $path ]($style)[](fg:bright-blue) ";
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
          # 右侧耗时色块：使用 bright-* 命名色，兼顾可读性与可维护性
          style = "bg:bright-yellow fg:black";
          # 右侧耗时显示为 pill（圆角胶囊）
          format = "[](fg:bright-yellow)[  $duration ]($style)[](fg:bright-yellow)";
          min_time = 0; # 单位：ms，500ms 即 0.5 秒
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
