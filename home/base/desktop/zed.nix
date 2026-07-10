{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.desktop.zed;
  lspPackages = config.modules.langs.lsp.packages;
  # OpenType Feature tags
  # 连字符相关配置
  # https://learn.microsoft.com/en-us/typography/opentype/spec/featurelist
  fontFeatures = {
    # Contextual Alternates)：上下文替换/上下文变体。不一定是"连字"，但编程字体里很多 !=→≠、---→长横线 这种"看起来像连字"的替换，常常就是放在 calt 里实现的
    calt = false;
    # Standard Ligatures)：标准连字。常见排印里的 fi/fl/ff 这类，很多字体也会把"常用符号组合连字"放这。
    liga = false;
    # Contextual Ligatures)：上下文连字。只有在特定上下文才触发（例如避免误触发、或在某些相邻字符下才替换）。
    clig = false;
    # Discretionary Ligatures)：可选/装饰性连字。更花哨，通常默认不开，给排版用户"我想要更装饰"的选择
    dlig = false;
    # Historical Ligatures)：历史连字。偏复古/历史排印用途
    hlig = false;
    # Required Ligatures)：必需连字。某些书写系统/字体需要它才能正确显示（在阿拉伯等连写脚本更常见），一般不建议随便关 !=
    rlig = false;
  };

  exts = {
    # MAYBE[2026-01-18]: 判断是否要
    # [The possibility to add custom language servers in configuration only · zed-industries/zed · Discussion #24092 · GitHub](https://github.com/zed-industries/zed/discussions/24092)

    "nix" = true;
    "rst" = true;

    "basher" = true;
    "biome" = true;
    "cargotoml" = true;
    "catppuccin-icons" = true;
    "git-firefly" = true;
    "marksman" = true;
    "snippets" = true;
    "toml" = true;
    "typos" = true;
    "zig" = true;
    "golangci-lint" = true;

    "justfile" = true;
    "nu" = true;
    "scss" = true;

    "svelte" = true;
    "lua" = true;
    "ini" = true;
    "astro" = true;
    "docker-compose" = true;
    "html" = true;
    "vue" = true;
    "dockerfile" = true;
    "make" = true;
    "sql" = true;
    "terraform" = true;
    "comment" = true;
    "log" = true;
    "oxc" = true;

    "mermaid" = true;
    "plantuml" = true;

    # "catppuccin"
    # "material-icon-theme"
    # "wakatime"
  };

  # ============================================================
  # 以下为配置文件的纯数据定义（JSON 兼容）
  # 由 home.file 管理 → Nix store symlink → immutable
  # ============================================================

  # --- userSettings → settings.json ---
  settings = {
    # [2026-01-17] 嵌套写法=dynamic，我需要static，所以直接写死。另外把 theme 从 Catpppuccin -> Monokai
    theme = "Monokai-Z";

    # icon_theme = Zed (Default);
    icon_theme = "Catppuccin Mocha";

    # 默认使用JB的键位
    base_keymap = "JetBrains";

    # https://zed.dev/docs/vim
    vim_mode = false;

    # 自动保存（默认off，所以需要自己手动设置）
    autosave = {
      after_delay = {
        milliseconds = 500;
      };
    };

    # 避免在日志/诊断/分享配置时泄露私密内容
    redact_private_values = true;

    # https://zed.dev/docs/reference/all-settings#file-types
    #
    # 补充文件类型识别，便于语法高亮/LSP
    file_types = {
      Dockerfile = [
        "Dockerfile"
        "Dockerfile.*"
      ];
      JSON = [
        "json"
        "jsonc"
        "*.code-snippets"
      ];
      "Ini" = [
        ".env"
        ".env.*"
        "*.env"
      ];
    };

    # 直接使用stylix的theme
    # [2026-01-12] stylix对GUI的处理有一定偏差，所以禁用了stylix管理，我们手动管理zed的theme
    # UI大小
    # [2026-01-17] 从16调整为15（14太小了）
    # [2026-07-03] 15 -> 14
    ui_font_size = 14;
    # 默认就是 .ZedSans，这里显式声明
    ui_font_family = ".ZedSans";

    # 编辑区字体大
    # [2026-01-18] 13太小 -> 14
    # [2026-07-03] 14 -> 13
    buffer_font_size = 13;
    buffer_font_weight = 100;

    tab_size = 2;
    preferred_line_length = 120;
    # 换行，按照editor编辑区的可用width自动调整
    soft_wrap = "editor_width";
    buffer_font_family = ".ZedMono";
    ui_font_weight = 100;
    # compact mode ()
    buffer_line_height = "standard";
    # Agent Panel 字体大小
    agent_buffer_font_size = 13;

    # Markdown Preview 字体大小（Zed 1.10.0 新增），独立于编辑区字体
    # [2026-07-09] 保持与 buffer_font_size 一致
    markdown_preview_font_size = 13;

    # 禁用OTel
    telemetry = {
      diagnostics = false;
      metrics = false;
    };

    # zed的scrollbar太粗了，所以禁用
    # [2026-01-12] bug已fix，所以改为system
    scrollbar = {
      show = "system";
    };

    # 在底部状态栏显示当前文件名（默认false）
    # 比 breadcrumbs 更轻量，不在编辑区上方额外占一行
    status_bar = {
      show_active_file = true;
    };

    # https://zed.dev/docs/configuring-zed#search
    #
    # 注意以下前4个配置项，只是用来配置，默认开关相应filter，而非相应按钮本身的展示与否
    # 所以都设置为false
    #
    search = {
      # 只匹配整词（缩小匹配范围）
      whole_word = false;
      case_sensitive = false;
      # 是否把 gitignored 文件也纳入搜索结果
      include_ignored = false;
      # 【用regex批量查找/替换】
      regex = false;
      # 是否在状态栏显示"项目搜索按钮"（不改变范围）
      button = true;
      # 导航匹配时是否居中显示（不改变范围，但影响体验）
      center_on_match = true;
    };

    # 用来给搜索结果 Wrap line
    # 默认true，这里显式声明
    search_wrap = true;

    # 新开搜索时，是否从光标处/选区自动填充查询内容（影响你启动搜索时的"默认范围感"。比如设成 selection 时更偏向"选区驱动"）
    seed_search_query_from_cursor = "always";
    # [智能大小写] 根据query调整case sensitivity，如果query包括uppercase，那就是大小写敏感。否则就不敏感
    use_smartcase_search = true;

    # https://zed.dev/docs/configuring-zed#file-scan-exclusions
    # 用来在搜索时，excludes这些文件
    #
    # why:
    # - 排除构建产物/工具目录，加快索引与搜索
    file_scan_exclusions = [
      # Default Items
      "**/.git"
      "**/.svn"
      "**/.hg"
      "**/.jj"
      "**/.sl"
      "**/.repo"
      "**/CVS"
      "**/.DS_Store"
      "**/Thumbs.db"
      "**/.classpath"
      "**/.settings"

      # Custom Items
      "**/node_modules"
      "**/dist"
      "**/.idea"

      # below from [jellydn/zed-101-setup]
      "**/out"
      "**/.husky"
      "**/.turbo"
      "**/.vscode-test"
      "**/.vscode"
      "**/.next"
      "**/.storybook"
      "**/.tap"
      "**/.nyc_output"
      "**/report"
    ];

    # 即使被 git ignore，也强制纳入 Zed 的扫描/搜索（用于 .env* 这类默认不想进 git 但又想可搜索的文件）；但仍会被 file_scan_exclusions 盖掉。
    # https://zed.dev/docs/configuring-zed#file-scan-inclusions
    file_scan_inclusions = [
      ".env*"
      "**/*.local.json"
    ];

    ########################

    # 禁用连字符
    buffer_font_features = fontFeatures;
    ui_font_features = fontFeatures;

    ############# Terminal ###############

    terminal = {
      alternate_scroll = "off";
      blinking = "terminal_controlled";
      copy_on_select = false;
      keep_selection_on_copy = true;
      # terminal 默认bottom，设置到右侧
      dock = "right";
      default_width = 640;
      default_height = 320;
      detect_venv = {
        on = {
          directories = [
            ".env"
            "env"
            ".venv"
            "venv"
          ];
          activate_script = "default";
        };
      };
      env = {
        # 终端中调用编辑器时等待 Zed 关闭
        # [2026-01-23] 注意是 zeditor 而非 zed
        # 这里指的是，在zed terminal里，EDITOR就被zed覆盖了
        #
        # [2026-01-23]
        # EDITOR = "zeditor --wait";
      };
      font_family = ".ZedMono";
      font_features = fontFeatures;
      # Terminal fontsize
      # [2026-01-18] 因为 Editor font 改为14，所以terminal font = 13
      font_size = 13;

      # [2026-01-17]  comfortable -> standard. 前者 line height 是 1.6，后者 1.3. 更紧凑，信息量更多。
      line_height = "standard";
      minimum_contrast = 45;
      option_as_meta = false;
      button = true;
      shell = "system";
      toolbar = {
        # 不需要开启 breadcrumbs（主要是目前UI太丑了，在Editor区上面展示。并且其实直接CMD+Shift+O 就可以直接看到当前文件的Path）
        breadcrumbs = false;
      };
      working_directory = "current_project_directory";

      scrollbar = {
        # 同上，同样因为zed的scrollbar太粗了
        show = "system";
      };
    };

    # 禁用
    toolbar = {
      breadcrumbs = false;
      quick_actions = false;
      selections_menu = false;
      agent_review = false;
      code_actions = false;
    };

    # 因为我设置了 TabTar = false
    # 所以 EditorTab 也没必要设置了
    #
    #
    # https://zed.dev/docs/reference/all-settings#editor-tabs
    tab_bar = {
      show = false;
      show_nav_history_buttons = false;
      show_tab_bar_buttons = false;
    };

    # 预览标签页（preview tabs）：文件导航时以预览方式打开，不创建新 tab
    preview_tabs = {
      enable_keep_preview_on_code_navigation = true;
      enable_preview_multibuffer_from_code_navigation = true;
      enable_preview_from_file_finder = true;
    };

    # 怎么用标签页管理多个项目（也就是在一个窗口打开多个项目）？
    # 仅限mac有该配置
    # 支持多个项目在同一个window，但是相应的如果配置后，就无法使用CMD+`来通过切换window来切换项目了。所以需要增加相应的自定义shortcut
    # [2026-01-17] 默认false，这里显式声明
    # 注意zed/vscode 的这个配置项，并没有做类似 goland 的那种Tab切换（本质来说是 IDE本身不支持该操作）
    # 1、想要用 CMD + ` 切换项目，就必须要设置为false
    # 2、一旦设置为true，所有项目确实可以作为Tab栏展示，但是就无法用 CMD + ` 切换了，也无法通过 CMD + Shift + ]/[ 切换。
    use_system_window_tabs = false;

    indent_guides = {
      enabled = true;
      line_width = 1;
      active_line_width = 1;

      # [2026-01-21] 改为 rainbow indentation，更清晰（但是bg仍然disable，否则会很干扰）
      coloring = "indent_aware";
      background_coloring = "disabled";
    };

    close_on_file_delete = true;

    # File Explorer Configuration
    # https://zed.dev/docs/configuring-zed#project-panel
    project_panel = {
      button = true;
      default_width = 240;
      # FE设置到左侧
      dock = "left";
      entry_spacing = "standard";
      file_icons = true;
      folder_icons = true;
      git_status = true;
      indent_size = 20;
      auto_reveal_entries = false;
      auto_fold_dirs = true;
      drag_and_drop = true;
      scrollbar = {
        show = "system";
      };
      sticky_scroll = true;
      show_diagnostics = "all";
      indent_guides = {
        show = "always";
      };
      hide_root = false;
      starts_open = true;
    };
    collaboration_panel = {
      button = false;
      # 设置为左侧布局
      dock = "left";
    };

    # Outline Panel Configuration
    # 相当于 IDEA 里面的 structure
    # https://zed.dev/docs/configuring-zed#outline-panel
    outline_panel = {
      button = true;
      default_width = 300;
      dock = "right";
      file_icons = true;
      folder_icons = true;
      git_status = true;
      indent_size = 20;
      # 让 outline 自动跟随编辑区移动（否则 右侧structure会回到最上面，而不是光标所在位置的structure）
      auto_reveal_entries = true;
      #
      auto_fold_dirs = true;
      # outline 缩进线
      indent_guides = {
        show = "always";
      };
      scrollbar = {
        show = null;
      };
    };

    # https://zed.dev/docs/configuring-zed#git-panel
    git_panel = {
      button = true;
      dock = "left";

      # 开启 Tree View，更清晰
      tree_view = true;
      default_width = 360;
      status_style = "icon";
      fallback_branch_name = "main";
      #
      sort_by_path = true;
      collapse_untracked_diff = true;
      scrollbar = {
        show = null;
      };
    };

    # Debugger Pannel
    debugger = {
      dock = "bottom";
    };

    restore_on_startup = "last_session";
    # 禁用所有内置 AI 功能（Agent Panel / Inline Assistant / Edit Prediction / Git commit 生成）
    # Claude Code/Codex 在外部终端直接使用，不走 Zed 内置 AI
    disable_ai = true;
    cursor_shape = "bar";

    # 意思很明确，Bottom Dock的layout（是否会挤占两侧Pane的Dock），默认 Contained (底部 dock 只占中间编辑区的宽度，而非 full 占据整个窗口宽度)，这里显式声明
    bottom_dock_layout = "contained";

    # Agent Configuration - Claude Code via ACP
    # Make sure you have the latest version of Zed
    # Find available agents in the Plus menu in the Agent Panel
    # agent = {
    #   provider = "claude-code";
    #   # Claude Code will run as an independent process via ACP
    #   # Zed provides the UI for following edits, reviewing changes, and managing tasks
    # };

    gutter = {
      line_numbers = true;
      runnables = true;
      breakpoints = true;
      folds = true;
      min_line_number_digits = 0;
    };

    # https://zed.dev/docs/configuring-zed#git
    git = {
      git_gutter = "hide";
      inline_blame = {
        enabled = true;
        # 显示在底部状态栏，不在代码行内，不干扰编辑区
        # （Zed 1.10.0 新增 location 选项）
        location = "status_bar";
      };
      branch_picker = {
        show_author_name = true;
      };
      hunk_style = "staged_hollow";

      # 双栏diff view
      diff_view_style = "split";
    };

    # 也就是 CMD+Shift+O 打开的文件搜索框
    #
    #
    # 默认的几个配置项都很很易用，不需要修改
    #
    # file_icons
    # modal_max_width
    # skip_focus_for_active_in_search
    #
    file_finder = {
      # 新开的pane出现在下面（默认up）
      # pane_split_direction_horizontal = "down";
    };

    # 禁用相对行号（默认false，显式声明）
    # 相对行号更利于 vim 式跳转/定位，但是我确实用不惯。
    #
    relative_line_numbers = "disabled";

    # hour_format = "hour24";

    # https://zed.dev/docs/configuring-zed#scroll-beyond-last-line
    # 默认 one_page. 在编辑区里，无论什么文件类型，都可以拉到最后一行，导致下面整块全都是一片空白
    # 完全禁用。文件底部将固定在编辑器的底端，无法继续向下滚动。
    scroll_beyond_last_line = "vertical_scroll_margin";

    # Remote Development Configuration
    # https://zed.dev/docs/remote-development
    ssh_connections = [
      {
        host = "100.81.204.63";
        args = [
        ];
        projects = [
          {
            paths = [
              "/home/luck/Desktop/docs"
              "/home/luck/Desktop/docs-alfred"
            ];
          }
        ];
        nickname = "homelab";
      }
    ];

    ############# Extensions ##############

    # https://zed.dev/docs/configuring-zed#auto-install-extensions
    # 注意 https://mynixos.com/home-manager/option/programs.zed-editor.extensions 也可以预配置 extensions
    # https://github.com/nix-community/home-manager/blob/master/modules/programs/zed-editor.nix#L32
    # [2026-01-18] zed的ext安装，用哪种更好？zed官方的conf，还是 hm的conf?
    # 可以看到本身 hm 的 extensions 配置项，也是借用 auto_install_extensions 实现的，二者本身是一码事。所以为啥不用zed本身提供的配置项呢？另外，hm的ext并不支持 auto_update_extensions，所以为了保证一致性和可维护性，我们把相应配置项做个整合
    auto_install_extensions = exts;
    auto_update_extensions = exts;

    ############# Languages ###############
    #
    #
    #

    # https://zed.dev/docs/reference/all-settings#inlay-hints
    inlay_hints = {
      enabled = true;
    };

    # https://zed.dev/docs/languages
    languages = {
      Markdown = {
        # 使用 tree-sitter 做 outline（document_symbols: off = 默认值），
        # 让 outline panel 正确显示 markdown heading 层级结构。
        #
        # WHY NOT marksman:
        #   之前因为没有更好的方案，切换到 marksman LSP 的
        #   textDocument/documentSymbol 做 outline，以避开 tree-sitter
        #   把 fenced code block 内的 # heading 识别为 atx_heading 的问题
        #   （参见 #32755 / #15122）。
        #   但实践发现 marksman 的 documentSymbol 响应以 SymbolKind=File 为根、
        #   heading 为 children，Zed outline panel 只展示顶层 symbol（文件名）
        #   而不展开 children，导致 outline 看不到 heading。
        #
        # WHY NOW (tree-sitter):
        #   PR #32987（v1.x 已合入）新增了跨语言 outline 过滤——来自 fenced
        #   code block 内的非 Markdown 符号不再进入 outline panel。这意味着
        #   最头疼的跨语言污染已解决。
        #   对于同一语言（Markdown）内 code block 产生的 atx_heading 污染，
        #   当前 Zed 版本的实际表现如何，需要验证。如果仍有问题，再考虑
        #   自定义 outline.scm extension 精确过滤。
        #
        # marksman 仍作为 Markdown 的主要 LSP 提供补全/跳转/诊断。
      };

      Nix = {
        language_servers = [
          "nil"
        ];
        format_on_save = "on";
        formatter = {
          external = {
            command = "nixfmt";
            arguments = [
              "--quiet"
            ];
          };
        };
      };

      YAML = {
        # WHAT: 关闭 YAML 的保存时自动格式化（Format on Save）。
        # WHY:
        #   你习惯在注释之间留空行，但很多 formatter（尤其是基于 prettier 风格的 YAML formatter）
        #   会在保存时重排空白行，导致"空行被吞/被合并"。关掉保存自动格式化后，
        #   Zed 不会在保存时替你改文本，你手写的空行能稳定保留。
        format_on_save = "off";
        # WHAT: 关闭"输入时格式化"（on-type formatting）。
        # WHY:
        #   即使你关了保存格式化，有些编辑器仍可能在你输入换行、缩进、补全等过程中触发格式化，
        #   也可能间接引发空白行/注释布局被改写。这里直接关掉，保证"只有你手动 Format 才会改"。
        use_on_type_format = false;
        tab_size = 2;
        # WHAT: 明确指定 YAML 语言使用的语言服务器（language servers）。
        # WHY:
        #   Zed 允许一个语言挂多个 LSP（甚至来自扩展的 server）。
        #   你希望 YAML 的行为（诊断/补全/格式化能力）尽量稳定、可预测，所以这里显式指定：
        #   - "yaml-language-server"：作为 YAML 的主要/标准 LSP（提供 schema、诊断、部分格式化能力等）
        #   - "!docker-compose"：把名为 docker-compose 的语言服务器从 YAML 的候选列表里排除
        #
        #   ⚠ 注意：
        #   - 这里的 "!docker-compose" 不是文件名匹配（不是"compose.yml 才排除"），
        #     它排除的是"语言服务器 ID/名称"。
        #   - 目的通常是避免 Docker Compose 扩展把自己的 YAML 解析/诊断混进来导致误报或行为冲突，
        #     让 YAML 统一由 yaml-language-server 处理。
        language_servers = [
          "yaml-language-server"
          "!docker-compose"
        ];
        # WHAT: 指定 YAML 的 formatter 使用 language_server。
        # WHY:
        #   Zed 对 YAML 默认可能走内置/外部 formatter（例如 prettier）。
        #   你这里显式选 "language_server" 的好处是：
        #   - 格式化逻辑与 YAML 的 LSP 保持一致（同一套 server、同一套 settings）
        #   - 方便在下方 lsp.yaml-language-server.settings.yaml.format.* 中集中控制格式化参数
        #
        #   同时你已经把 format_on_save 关掉了，所以这不会影响"保存吞空行"的问题；
        #   它只决定你手动触发 Format 时使用谁来格式化。
        formatter = "language_server";
      };

      JSON = {
        # WHAT: 保留 JSON 的保存时自动格式化（Format on Save）。
        # WHY:
        #   你希望继续享受 auto format，但必须保证输出是严格 JSON，
        #   不能因为 formatter 风格引入 trailing comma，导致 pre-commit check-json 失败。
        format_on_save = "on";
        use_on_type_format = true;
        formatter = {
          external = {
            command = "prettier";
            arguments = [
              "--stdin-filepath"
              "{buffer_path}"
              # 强制关闭 trailing comma，避免生成不被 strict JSON 接受的尾逗号。
              "--trailing-comma"
              "none"
            ];
          };
        };
      };

      JSONC = {
        # WHY:
        #   Zed 的一些配置文件（例如 .zed/settings.json）实际会按 JSONC 语义处理。
        #   这里同步对 JSONC 关闭 trailing comma，防止 autosave 后再次写入尾逗号。
        format_on_save = "on";
        use_on_type_format = true;
        formatter = {
          external = {
            command = "prettier";
            arguments = [
              "--stdin-filepath"
              "{buffer_path}"
              "--trailing-comma"
              "none"
            ];
          };
        };
      };

      Go = {
        language_servers = [
          # 保留默认LSP，再追加
          "..."

          "gopls"

          # golangci-lint 并非预配置LSP，所以这里手动配置
          "golangci-lint"
        ];
      };

      Python = {
        tab_size = 4;
        format_on_save = "on";
        # formatter = "language_server";
        formatter = {
          language_server = {
            name = "ruff";
          };
        };

        # pyright 负责类型分析，ruff 负责 lint/format
        language_servers = [
          "pyright"
          "ruff"
        ];
      };

      JavaScript = {
        formatter = {
          external = {
            command = "prettier";
            arguments = [
              "--stdin-filepath"
              "{buffer_path}"
            ];
          };
        };
        format_on_save = "on";
        tab_size = 2;
      };

      TypeScript = {
        # 走 LSP（vtsls/typescript-language-server）的 textDocument/documentSymbol
        # 可以获得更丰富的 outline 信息（interface 展开、type 别名、模块导出等），
        # 比默认的 tree-sitter 查询更完整。
        document_symbols = "on";
        # 显式声明，覆盖 Zed 1.10.0 默认禁用的 format_on_save
        format_on_save = "on";
        inlay_hints = {
          enabled = true;
          show_parameter_hints = false;
          show_other_hints = true;
          show_type_hints = true;
        };
      };
    };

    lsp = {
      nil = {
        settings = {
          nix = {
            flake = {
              # [2026-01-17] nil 需要读取 flake inputs 才能完成 nix LSP 能力；
              # 但 Zed 的 LSP 客户端不支持"确认弹窗"，当 inputs 未归档时会反复提示
              # Some flake inputs are not available, please run nix flake archive。
              # 启用 autoArchive 后，nil 会自动执行等价的归档流程，避免该提示并保证 LSP 正常工作。
              # 仍可在 flake 根目录手动运行 `nix flake archive` 以预热。
              autoArchive = true;

              # what: 用来控制 nil 是否会自动评估 flake 的 inputs（例如调用 nix flake show 去获取 inputs 的 outputs/结构），以提供更准确的补全与类型推断。
              # why (false): 在 evaluate sops-nix 时，会触发对不存在路径（如 dev/private）的访问，导致 nix flake show 失败并在 Zed 里报错。所以设置为false
              autoEvalInputs = false;
            };
          };
        };
      };

      yaml-language-server = {
        settings = {
          yaml = {
            format = {
              enable = true;
              # WHAT: 设置"打印宽度/换行阈值"为 3000。
              # WHY:
              #   这对应你在 yamllint 里 "line-length max: 3000" 的偏好：
              #   你宁愿保持一行很长，也不希望 formatter 自动折行。
              #   设置很大可以显著减少 formatter 引入的换行 diff。
              printWidth = 3000;
              # WHAT: 控制类似 `{ a: 1 }` / `{a: 1}` 这种"花括号内是否保留空格"的倾向。
              # WHY:
              #   你在其它语言（TS/Prettier）也很在意这类 spacing 一致性。
              #   对 YAML formatter 来说，bracketSpacing=false 通常更"紧凑"，
              #   能避免在括号内自动插入空格（减少你不想要的风格改动）。
              bracketSpacing = false;
            };
          };
        };
      };

      # 告诉 Tailwind LSP 这些字段也包含 class，保证补全/提示生效。
      tailwindcss-language-server = {
        settings = {
          classAttributes = [
            "class"
            "className"
            "ngClass"
            "styles"
          ];
        };
      };
    };
  };

  # --- userKeymaps → keymaps.json ---
  keymaps = [
    # 非 vim mode：只保留不依赖 vim 的快捷键
    {
      context = "Editor";
      bindings = {
        ctrl-h = "workspace::ActivatePaneLeft";
        ctrl-l = "workspace::ActivatePaneRight";
        ctrl-k = "workspace::ActivatePaneUp";
        ctrl-j = "workspace::ActivatePaneDown";
      };
    }
    {
      context = "Terminal";
      bindings = {
        ctrl-h = "workspace::ActivatePaneLeft";
        ctrl-l = "workspace::ActivatePaneRight";
        ctrl-k = "workspace::ActivatePaneUp";
        ctrl-j = "workspace::ActivatePaneDown";
      };
    }
    {
      context = "ProjectPanel && not_editing";
      bindings = {
        a = "project_panel::NewFile";
        A = "project_panel::NewDirectory";
        r = "project_panel::Rename";
        d = "project_panel::Delete";
        x = "project_panel::Cut";
        c = "project_panel::Copy";
        p = "project_panel::Paste";
        q = "workspace::ToggleRightDock";
        ctrl-h = "workspace::ActivatePaneLeft";
        ctrl-l = "workspace::ActivatePaneRight";
        ctrl-k = "workspace::ActivatePaneUp";
        ctrl-j = "workspace::ActivatePaneDown";
      };
    }
    {
      context = "Dock";
      bindings = {
        "ctrl-w h" = "workspace::ActivatePaneLeft";
        "ctrl-w l" = "workspace::ActivatePaneRight";
        "ctrl-w k" = "workspace::ActivatePaneUp";
        "ctrl-w j" = "workspace::ActivatePaneDown";
      };
    }
    {
      context = "Workspace";
      bindings = {
        cmd-b = "workspace::ToggleRightDock";
      };
    }
    # 禁用 CMD +/- 字体缩放快捷键（容易误触）
    {
      context = "Workspace";
      bindings = {
        "cmd-+" = null;
        "cmd-=" = null;
        "cmd--" = null;
      };
    }
  ];

  # --- userTasks → tasks.json ---
  tasks = [
    # https://github.com/zed-industries/extensions/issues/523#issuecomment-3325210094
    {
      "label" = "List TODO/FIXME"; # 任务名称（在 Zed 任务列表里显示）
      "command" = "rg"; # 实际执行的命令（ripgrep）
      "args" = [
        "--vimgrep" # 输出包含 行/列 的格式，便于跳转
        "--hyperlink-format=file://{path}:{line}:{column}" # 生成带行列的超链接
        "-e TODO:"
        "-e PLAN:"
        "-e MAYBE:"
        "." # 搜索起点（当前工作区根目录）
      ];
      "cwd" = "\${ZED_WORKTREE_ROOT}"; # 在当前工作区根目录执行
      "use_new_terminal" = true; # 在新终端运行，避免占用已有终端
      "allow_concurrent_runs" = false; # 禁止并发执行，避免结果交错
      "reveal" = "always"; # 总是展示任务输出面板
      "hide" = "never"; # 不自动隐藏任务输出
      "show_summary" = true; # 展示任务摘要
      "show_command" = true; # 展示实际运行的命令
      "reveal_target" = "center"; # 输出面板出现时居中
    }
  ];

  # --- themes（独立文件 ~/.config/zed/themes/monokai.json） ---
  monokaiTheme = {
    "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";

    name = "Monokai";
    author = "lucas";
    themes = [
      {
        name = "Monokai-Z";
        appearance = "dark";
        style = {
          background = "#272822";
          "background.appearance" = "opaque";
          border = "#131310";
          "border.disabled" = "#161613";
          "border.focused" = "#6e7066";
          "border.selected" = "#161613";
          "border.transparent" = "#161613";
          "border.variant" = "#131310";
          conflict = "#fd971f";
          created = "#a6e22e";
          deleted = "#f92672";
          "drop_target.background" = "#161613bf";
          # 对齐 IDEA CARET_ROW_COLOR = #3E3D32（Zed 支持活动行背景）
          # "editor.active_line.background" = "#fdfff10c";
          "editor.active_line.background" = "#3e3d32";
          "editor.active_line_number" = "#fdfff1";
          # 对齐 IDEA INDENT_GUIDE / SELECTED_INDENT_GUIDE = #464741
          # "editor.active_wrap_guide" = "#161613";
          "editor.active_wrap_guide" = "#464741";
          "editor.background" = "#272822";
          # 对齐 IDEA IDENTIFIER_UNDER_CARET_ATTRIBUTES 背景 = #3C3C57
          # "editor.document_highlight.read_background" = "#3d3e38";
          "editor.document_highlight.read_background" = "#3c3c57";
          # 对齐 IDEA WRITE_IDENTIFIER_UNDER_CARET_ATTRIBUTES 背景 = #472C47
          "editor.document_highlight.write_background" = "#472c47";
          # 对齐 IDEA MATCHED_BRACE_ATTRIBUTES 背景 = #3A6DA0
          "editor.document_highlight.bracket_background" = "#3a6da0";
          # 对齐 IDEA TEXT 前景色（#f8f8f2）
          # "editor.foreground" = "#fdfff1";
          "editor.foreground" = "#f8f8f2";
          "editor.gutter.background" = "#272822";
          # 对齐 IDEA LINE_NUMBERS_COLOR = #F8F8F2
          # "editor.line_number" = "#57584f";
          "editor.line_number" = "#f8f8f2";
          "editor.subheader.background" = "#20211c";
          # 对齐 IDEA INDENT_GUIDE / WHITESPACES = #464741
          # "editor.wrap_guide" = "#131310";
          "editor.wrap_guide" = "#464741";
          # 对齐 IDEA INDENT_GUIDE = #464741
          "editor.indent_guide" = "#464741";
          # 对齐 IDEA SELECTED_INDENT_GUIDE = #464741（无单独色则与普通一致）
          "editor.indent_guide_active" = "#464741";
          # 对齐 IDEA WHITESPACES = #464741
          "editor.invisible" = "#464741";
          "element.background" = "#3b3c35";
          "element.hover" = "#20211c";
          "element.selected" = "#fdfff10c";
          "elevated_surface.background" = "#20211c";
          error = "#f92672";
          "error.background" = "#20211c";
          "error.border" = "#131310";
          "ghost_element.hover" = "#fdfff10c";
          "ghost_element.selected" = "#fdfff10c";
          hidden = "#919288";
          hint = "#919288";
          "hint.background" = "#20211c";
          "hint.border" = "#131310";
          ignored = "#57584f";
          info = "#e6db74";
          "info.background" = "#20211c";
          "info.border" = "#131310";
          "link_text.hover" = "#fdfff1";
          modified = "#fd971f";
          "pane_group.border" = "#131310";
          "panel.background" = "#20211c";
          "panel.focused_border" = "#ffffff20";
          players = [
            {
              background = "#fdfff1";
              cursor = "#fdfff1";
              selection = "#fdfff11a";
            }
            {
              background = "#f92672";
              cursor = "#f92672";
              selection = "#f926721a";
            }
            {
              background = "#a6e22e";
              cursor = "#a6e22e";
              selection = "#a6e22e1a";
            }
            {
              background = "#fd971f";
              cursor = "#fd971f";
              selection = "#fd971f1a";
            }
            {
              background = "#e6db74";
              cursor = "#e6db74";
              selection = "#e6db741a";
            }
            {
              background = "#ae81ff";
              cursor = "#ae81ff";
              selection = "#ae81ff1a";
            }
            {
              background = "#66d9ef";
              cursor = "#66d9ef";
              selection = "#66d9ef1a";
            }
          ];
          predictive = "#919288";
          "scrollbar.thumb.active_background" = "#fdfff159";
          "scrollbar.thumb.background" = "#c0c1b526";
          "scrollbar.thumb.border" = "#c0c1b526";
          "scrollbar.thumb.hover_background" = "#fdfff126";
          "scrollbar.track.background" = "#272822";
          "scrollbar.track.border" = "#272822";

          # 对齐 IDEA TEXT_SEARCH_RESULT_ATTRIBUTES 背景 = #5F5F00
          # [2026-01-22] 改成亮黄色，更显眼
          #
          # "search.match_background" = "#3d3e38";
          # "search.match_background" = "#5f5f00";
          "search.match_background" = "#ffcc00";

          "status_bar.background" = "#20211c";
          "surface.background" = "#3b3c35";
          syntax = {
            attribute = {
              color = "#66d9ef";
              font_style = "italic";
            };
            boolean = {
              color = "#ae81ff";
            };

            # [2026-01-17] 参考IDEA的monokai 修改，让comment更清晰
            comment = {
              # color = "#6e7066";
              color = "#75715E";
              font_style = "italic";
            };

            # [2026-07-03] 文档注释也跟普通注释保持一致，避免比正常注释更灰
            "comment.doc" = {
              color = "#75715E";
              font_style = "italic";
            };
            constant = {
              color = "#ae81ff";
            };
            constructor = {
              color = "#f92672";
            };
            emphasis = {
              font_style = "italic";
            };
            "emphasis.strong" = {
              font_weight = 700;
            };
            # Zed 只有单一 function 色位：取 IDEA 函数声明色 #a6e22e
            # function = { color = "#a6e22e"; };
            function = {
              color = "#a6e22e";
            };
            keyword = {
              color = "#f92672";
            };
            label = {
              color = "#a6e22e";
            };
            link_text = {
              # 对齐 IDEA：Markdown 链接文本改为浅蓝（原先红色留给 Markdown 结构符号）
              color = "#c7c7ff";
            };
            link_uri = {
              color = "#a6e22e";
            };
            number = {
              color = "#ae81ff";
            };
            operator = {
              color = "#f92672";
            };
            preproc = {
              color = "#ae81ff";
            };
            # [2026-01-17] 原目标是只改 YAML 的 key 颜色，但 Zed 目前无法在主题层面按语言区分 key。
            # 原因：
            # 1) 主题只认识 Tree-sitter 的 capture（如 property），对同名 capture 是全局生效的。
            # 2) YAML 的 key 当前 capture 只有 property（已通过 editor: copy highlight json 验证）。
            # 3) zed.dev/docs/languages/yaml 主要是 LSP/格式化/Schema，不提供更细粒度的 key 高亮配置入口。
            # 可行但更复杂的方案（未采用）：
            # - 自建/本地 language extension，提供 languages/yaml/highlights.scm。
            # - 在 highlights.scm 中把 YAML key 捕获为 @property.yaml_key。
            # - 主题里再配置 syntax."property.yaml_key" = { color = "#f92672"; } 以实现"只改 YAML"。
            # 结论：为保持配置简单与可维护性，最终选择全局修改所有语言的 key（property）。
            property = {
              color = "#f92672";
            };
            # 对齐 IDEA：标点多继承默认前景色（接近 #f8f8f2）
            # punctuation = { color = "#919288"; };
            # "punctuation.bracket" = { color = "#919288"; };
            # "punctuation.delimiter" = { color = "#919288"; };
            # "punctuation.list_marker" = { color = "#919288"; };
            # "punctuation.special" = { color = "#919288"; };
            punctuation = {
              # Markdown code fence / emphasis 等符号统一改红（全局标点会受影响）
              color = "#f92672";
            };
            "punctuation.bracket" = {
              color = "#f8f8f2";
            };
            "punctuation.delimiter" = {
              color = "#f8f8f2";
            };
            "punctuation.list_marker" = {
              # Markdown 无序/有序列表标记改红（全局 list marker 会受影响）
              color = "#f92672";
            };
            "punctuation.special" = {
              color = "#f8f8f2";
            };
            string = {
              color = "#e6db74";
            };
            # 对齐 IDEA VALID_STRING_ESCAPE = #ae81ff
            # "string.escape" = { color = "#fdfff1"; };
            "string.escape" = {
              color = "#ae81ff";
            };
            "string.regex" = {
              color = "#e6db74";
            };
            "string.special" = {
              color = "#fd971f";
            };
            "string.special.symbol" = {
              color = "#fd971f";
            };
            tag = {
              color = "#f92672";
            };

            # Markdown heading 改成红色
            # 注意在Zed里，整个heading是作为整体出现的（而非拆分为 # 和 title内容 两部分，所以渲染时，也只能作为整体渲染为红色）"标题整行是一个 title capture（# 和文字都在一起）"
            title = {
              color = "#f92672";
            };
            # 同上，只能作为整体进行渲染
            "text.literal" = {
              color = "#e6db74";
            };

            # 对齐 IDEA CLASS_REFERENCE / TYPE_REFERENCE = #a6e22e
            # type = { color = "#66d9ef"; };
            type = {
              color = "#a6e22e";
            };
            variable = {
              color = "#fdfff1";
            };
            "variable.special" = {
              color = "#ae81ff";
            };
          };
          "tab.active_background" = "#272822";
          "tab.inactive_background" = "#20211c";
          "tab_bar.background" = "#20211c";
          # 终端颜色对齐 IDEA Console 输出色
          # "terminal.ansi.black" = "#3b3c35";
          "terminal.ansi.black" = "#272822";
          # "terminal.ansi.blue" = "#fd971f";
          "terminal.ansi.blue" = "#c7c7ff";
          # "terminal.ansi.bright_black" = "#6e7066";
          "terminal.ansi.bright_black" = "#a7a7a7";
          # "terminal.ansi.bright_blue" = "#fd971f";
          "terminal.ansi.bright_blue" = "#c7c7ff";
          # IDEA Console CYAN 输出值为 #6b8b8（位数异常），先保留原值
          # "terminal.ansi.bright_cyan" = "#66d9ef";
          "terminal.ansi.bright_cyan" = "#66d9ef";
          # "terminal.ansi.bright_green" = "#a6e22e";
          "terminal.ansi.bright_green" = "#68e868";
          # "terminal.ansi.bright_magenta" = "#ae81ff";
          "terminal.ansi.bright_magenta" = "#ff2eff";
          # "terminal.ansi.bright_red" = "#f92672";
          "terminal.ansi.bright_red" = "#ff6767";
          # "terminal.ansi.bright_white" = "#fdfff1";
          "terminal.ansi.bright_white" = "#ffffff";
          # "terminal.ansi.bright_yellow" = "#e6db74";
          "terminal.ansi.bright_yellow" = "#754200";
          # IDEA Console CYAN 输出值为 #6b8b8（位数异常），先保留原值
          # "terminal.ansi.cyan" = "#66d9ef";
          "terminal.ansi.cyan" = "#66d9ef";
          # "terminal.ansi.green" = "#a6e22e";
          "terminal.ansi.green" = "#68e868";
          # "terminal.ansi.magenta" = "#ae81ff";
          "terminal.ansi.magenta" = "#ff2eff";
          # "terminal.ansi.red" = "#f92672";
          "terminal.ansi.red" = "#ff6767";
          # "terminal.ansi.white" = "#fdfff1";
          "terminal.ansi.white" = "#ffffff";
          # "terminal.ansi.yellow" = "#e6db74";
          "terminal.ansi.yellow" = "#754200";
          "terminal.background" = "#272822";
          text = "#fdfff1";
          "text.accent" = "#e6db74";
          "text.muted" = "#919288";
          "title_bar.background" = "#161713";
          "toolbar.background" = "#272822";
          "vim.insert.background" = "#a6e22e";
          "vim.mode.text" = "#272822";
          "vim.normal.background" = "#e6db74";
          "vim.visual.background" = "#fd971f";
          warning = "#fd971f";
          "warning.background" = "#20211c";
          "warning.border" = "#131310";
        };
      }
    ];
  };
in
{
  options.modules.desktop.zed = {
    enable = lib.mkEnableOption "Enable zed (client)";
    # 远程/headless 模式（用于 headless server，无 GUI）
    remote.enable = lib.mkEnableOption "Enable zed remote server (headless)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      programs.zed-editor = {
        # macOS 上 nixpkgs 的 zed 版本过于落后且与 brew cask 冲突，
        # 所以 macOS 不走 HM 管理 app bundle（仅管理配置文件，由 home.file 提供），
        # 直接使用 brew cask 安装的 /Applications/Zed.app
        enable = pkgs.stdenv.isLinux;
        package = lib.mkIf pkgs.stdenv.isLinux pkgs.zed-editor;

        extraPackages = lspPackages;

        # 配置由 home.file 管理（Nix store symlink → immutable），
        # 不清空 userSettings 会导致 zed 模块与 home.file 争管同一文件。
        userSettings = { };
        userKeymaps = [ ];
        userTasks = [ ];
      };

      # 用 home.file 做 immutable symlink，避免 Zed 直接改写导致 drift
      # 所有配置需改 zed.nix → deploy 才能生效，不再通过 Zed GUI 修改
      home.file = {
        ".config/zed/settings.json" = {
          text = builtins.toJSON settings;
          force = true;
        };
        ".config/zed/keymaps.json" = {
          text = builtins.toJSON keymaps;
          force = true;
        };
        ".config/zed/tasks.json" = {
          text = builtins.toJSON tasks;
          force = true;
        };
        # theme 独立文件，Zed 会自动加载 ~/.config/zed/themes/*.json
        ".config/zed/themes/monokai.json" = {
          text = builtins.toJSON monokaiTheme;
          force = true;
        };
      };
    })

    (lib.mkIf cfg.remote.enable {
      # 远程/headless 模式：提供 LSP 工具链 + Zed remote server 二进制路径
      home.packages = lspPackages;

      # home.file.".zed_server" = {
      #   source = "${pkgs.zed-editor.remote_server}/bin";
      #   recursive = true;
      # };
    })
  ];
}
