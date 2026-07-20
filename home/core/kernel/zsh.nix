{
  lib,
  pkgs,
  config,
  editorMeta,
  ...
}:
{
  home = {
    packages = with pkgs; [
      zsh-completions
      carapace
    ];

    # 环境变量
    # Note: Dynamic variables (those using command substitution) are set in zsh initContent
    # PATH 使用 home.sessionPath（由 zsh 模块在 .zprofile 中加载，避免系统 PATH 覆盖问题）
    # 参考 home-manager PR #9356（已合并，修复了 #2991）
    sessionPath = [
      "$HOME/go/bin"
      "$HOME/.bun/bin"
      # [2026-05-16] pnpm >= 11 的 global-bin-dir 默认为 $PNPM_HOME/bin
      "$PNPM_HOME/bin"
    ];

    sessionVariables = {
      # 通用配置
      # EDITOR = editorMeta.command;
      # BROWSER = "chromium-browser";
      PNPM_HOME = "$HOME/.local/share/pnpm";

      # Locale（单源在 sessionVariables；交互 zsh 不再在 zsh-init 里 export）
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
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
    bash = {
      enable = true;
    };

    zsh = {
      enable = true;
      # NOTE: 固定 legacy 行为，避免 HM 将来默认切到 XDG 路径导致行为变化。
      # 如后续要迁移，可改成 "${config.xdg.configHome}/zsh" 并同步迁移历史/插件文件。
      dotDir = config.home.homeDirectory;
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

      # 覆盖 HM 默认 `compinit`：无 -C 时每次交互启动会重写 ~/.zcompdump（本机实测 ~300ms+）。
      # -C 跳过 security check 并复用 dump；fpath 大变后若不生效：rm ~/.zcompdump && exec zsh
      # 顺序锚点：completionInit/compinit ≈ 570 → carapace 600 → fzf-tab 650 → autosuggestions 700
      completionInit = ''
        autoload -Uz compinit
        compinit -C -d "${config.home.homeDirectory}/.zcompdump"
      '';

      # 为命令行着色（合法命令绿色、未知命令红色等）
      syntaxHighlighting = {
        enable = true;
        styles = {
          # 未知命令 -> 红色；其余采用默认主题
          "unknown-token" = "fg=red,bold";
        };
      };

      # 命令行自动补全/联想（zsh-autosuggestions）
      # 相较 modules 缺少 async
      autosuggestion = {
        enable = true;
        # 仅从历史里提示，避免与补全菜单冲突；若想更激进可加 "completion"
        strategy = [ "history" ];
        # 低调暗灰，避免喧宾夺主（原 fg=cyans 非法色名）
        highlight = "fg=8";
      };

      # 结构化 zsh 选项配置
      # 文件历史：接受 HM history 默认 share_history（勿再设 append_history，会被 NO_APPEND_HISTORY 盖掉）
      # 历史搜索以 atuin 为准；hist_ignore_* 由下方 history 块处理
      setOptions = [
        "hist_verify" # 历史展开时先验证
        "hist_no_store" # 不存储 history 命令本身

        # 便利性（autocd 已由 programs.zsh.autocd 开启，不在此重复 auto_cd）
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
        # 覆盖 eza enableZshIntegration 的 mkDefault ll='eza -l'（要 -la）
        ll = "eza -la";
        la = "eza -a";
        lls = "eza -la --sort=size --reverse --total-size";
        "md" = "mkdir -p";
        "rd" = "rmdir";

        # 编辑器
        "vim" = "LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 ${editorMeta.command}";

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
        v = "${editorMeta.command} .";
      };

      # 启用后 HM 会设 SHARE_HISTORY 等；与 setOptions 对齐，搜索侧用 atuin
      history = {
        size = 10000;
        save = 10000;
        ignoreDups = true;
        ignoreSpace = true;
      };

      # 使用新的 initContent 替代 deprecated 的 initExtraBeforeCompInit 和 initExtra
      initContent = lib.mkMerge [
        (lib.mkOrder 550 (builtins.readFile ./zsh-init.zsh))

        # fzf-tab
        # fzf-tab 必须放在 compinit 之后、autosuggestions 之前。
        #  - compinit 在 programs.zsh.completionInit 阶段执行
        #  - autosuggestions 会在更后面 wrap ZLE widgets
        #  - programs.zsh.plugins 的 source 位点比 autosuggestions 更晚
        #  而 fzf-tab 要求位于 compinit 之后、autosuggestions 之前，所以这里不用 programs.zsh.plugins，
        #  改为手动插入一个有序的 initContent 片段。
        # Home Manager 当前顺序里：
        # - completionInit / compinit: 570
        # - autosuggestions: 700
        # 因此这里显式卡在中间，避免被 programs.zsh.plugins 的更晚 source 顺序破坏。
        #
        # carapace: 多 shell 补全引擎，增强 zsh tab 补全数据源
        (lib.mkOrder 600 ''
          source <(${pkgs.carapace}/bin/carapace _carapace zsh)
        '')

        (lib.mkOrder 650 ''
          source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
        '')
      ];

      # zsh 退出时执行的命令
      logoutExtra = ''
        # 清理临时文件或执行其他清理操作
        # 目前保持空白以最大化性能
      '';

      # PATH 设置由 home.sessionPath 统一管理（见上方 home 层级配置）
      # 之前因 home-manager #2991（zsh 中 home.sessionPath 被系统 PATH 覆盖）而在此手动设置
      # 该 bug 已由 PR #9356 修复（2026-06-02 合并），故改用 home.sessionPath
    };

    nushell = {
      enable = true;

      # 环境变量配置
      environmentVariables = {
        # 编辑器配置
        EDITOR = editorMeta.command;
        VISUAL = editorMeta.command;
      };

      # Nushell 核心设置
      settings = {
        # 关闭欢迎信息
        show_banner = false;

        # 历史配置
        history = {
          file_size = 1 * 1024 * 1024; # 1MB
          max_size = 100000;
          sync_on_enter = true;
          file_format = "sqlite";
        };

        # 完成配置
        completions = {
          external = {
            enable = true;
            max_results = 100;
            completer = {
              # 使用外部完成器
              case_sensitive = false;
            };
          };
        };

        # 错误显示
        error_style = "fancy";
        display_errors = {
          exit_code = true;
        };

        # 表格显示
        table = {
          mode = "rounded"; # rounded,basic,compact,compact_double,light,thin
          index_mode = "always"; # always,never,auto
          trim = {
            methodology = "truncating"; # wrapping,truncating
            max_length = 80;
          };
        };

        # 文件大小显示
        filesize = {
          metric = true; # 使用公制 (KB, MB) 而不是二进制 (KiB, MiB)
          format = "auto"; # auto,b,kb,kib,mb,mib,gb,gib,tb,tib,pb,pib,eb,eib,zb,zib
        };

        # 钩子配置
        hooks = {
          pre_execution = "";
          pre_prompt = "";
        };
      };

      plugins = with pkgs.nushellPlugins; [
        # 格式支持插件
        formats
        # 可以添加更多插件：
        # inc
        # query
        # gstat
      ];
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
        key_path = config.sops.secrets.AUTIN_KEY.path;
        # session token：登录云端 API 的“会话令牌”，通常是一个带连字符的 UUID 字符串。
        session_path = config.sops.secrets.AUTIN_SESSION.path;

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
