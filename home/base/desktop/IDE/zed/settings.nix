_: let
  # OpenType Feature tags
  # 连字符相关配置
  # https://learn.microsoft.com/en-us/typography/opentype/spec/featurelist
  fontFeatures = {
    # Contextual Alternates)：上下文替换/上下文变体。不一定是“连字”，但编程字体里很多 !=→≠、---→长横线 这种“看起来像连字”的替换，常常就是放在 calt 里实现的
    calt = false;
    # Standard Ligatures)：标准连字。常见排印里的 fi/fl/ff 这类，很多字体也会把“常用符号组合连字”放这。
    liga = false;
    # Contextual Ligatures)：上下文连字。只有在特定上下文才触发（例如避免误触发、或在某些相邻字符下才替换）。
    clig = false;
    # Discretionary Ligatures)：可选/装饰性连字。更花哨，通常默认不开，给排版用户“我想要更装饰”的选择
    dlig = false;
    # Historical Ligatures)：历史连字。偏复古/历史排印用途
    hlig = false;
    # Required Ligatures)：必需连字。某些书写系统/字体需要它才能正确显示（在阿拉伯等连写脚本更常见），一般不建议随便关 !=
    rlig = false;
  };

  exts = import ./extensions.nix;
in {
  # [2025-10-12] 目前zed相较goland的一些缺失功能
  # - [git side-by-side viewer] https://github.com/zed-industries/zed/discussions/26770
  #
  # - ✅ [highlight] https://github.com/zed-industries/zed/issues/11895
  # https://github.com/zed-industries/zed/pull/9082
  #
  # - ✅ [通过CMD+`切换项目] 怎么通过 CMD+` 快捷键，直接在多个project之间切换？我在配置 use_system_window_tabs 之前，本身通过 CMD+` 这种mac本身提供的窗口切换来切换项目是可行的，但是在添加该配置之后，因为本身没有多窗口了，所以怎么需要配置哪个快捷键来保证类似操作？
  #
  # - ✅ [类似CMD+E切换最近修改文件]
  # 直接用 Ctrl+Tab 切换一样的。但是存在一些bug
  #
  #
  # - ✅ [内存开销并不低] LSP没有lazy load机制，默认LSP很多都是node实现的，单个进程都在80MB，开10个就是800MB内存开销

  # [2026-01-12] 尝试Remote Development，所以再次尝试zed，最终证实仍然不好用
  #
  # - ✅ [theme] 没有好theme，我只喜欢Monokai，但是挑了不少theme都很丑（完全不如goland内置的Color Scheme）。很多人都认为zed本身有色差（很糊，相较于goland，很多字都看不清，费眼睛），我也这么认为。
  #
  # - [git] 同样是 changelist/staging，但是zed并不支持path（这样就很不清晰）
  #
  #
  # - 🔀 [scratch] 没有scratch（当然可以通过 CMD+shift+P 里使用 workspace: new file 可以打开一个类似goland里Buffer的文件，但是1、不支持文件类型。2、不支持通过shortcut直接打开scratches列表）
  # 用 nb cli + zed task 替代实现了
  #
  #
  #
  # - 🔀 [DB插件] 用 webapp 替代了（这个feat也没必要强求）
  #
  #
  # - 🔀 [TODO-Tree] 一个高频需求，社区也有很多实现。目前的问题在于 交付形态。zed官方希望最终效果是类似 goland/vscode 的那种在Pannel展示的 TODO Tree，但是 目前zed官方不打算实现这个需求，而extension开发也没有提供UI支持，这样社区也没办法做这个需求。所以可能暂时无法实现该需求。
  # 目前的
  # https://github.com/alexandretrotel/todo-tree
  # https://github.com/alexandretrotel/zed-todo-tree
  # [Add todo-tree extension using Zed tasks by alexandretrotel · Pull Request #4401 · zed-industries/extensions](https://github.com/zed-industries/extensions/pull/4401)
  #
  # https://github.com/zed-industries/extensions/issues/523
  # https://github.com/Gruntfuggly/todo-tree

  # [2026-01-18]
  #
  # - 🔀 [git commit history]
  # 用 tig, serie 可以替代实现该需求
  #
  #
  #
  # https://www.reddit.com/r/ZedEditor/comments/1mvqlph/zed_is_awesome_but_it_lacks_some_crucial/
  # 这篇文章的吐槽挺到位的
  # - 配置体验不一致：有的设置用 true/false，有的用 "enabled"/"disabled"，还有 "on"/"off"，即便只是二选一也不统一，观感和可维护性都很差。
  #
  # - Ctrl+Click 跳转/引用的交互很别扭（最大痛点）：
  #
  # - 在 VSCode 里常见的是“peek 小窗”或直接跳转；但在 Zed 里 Ctrl+Click 会先开一个“搜索式的新 tab”展示引用/定义，然后还得 Alt+Enter 再跳转，楼主觉得这是多余的中间步骤，极其影响效率。
  #
  # - 补全不带括号：方法名补全后只插入方法名，不自动补 ()（楼主认为 VSCode 往往能调）。
  #
  # - 改键删除的行为反直觉：删掉 keybinding 时不是移除条目/按键，而是把 command 变成 <null>，等于“保留壳子”，让人困惑。
  #
  # - 标签页管理能力弱：找不到“多行 tab wrap”或“显示当前打开 tab 数量”等，导致可见 tab 很少，需要疯狂横向滚动或完全依赖
  #
  #
  #
  #
  #
  # - [Local History] https://github.com/zed-industries/zed/discussions/24004
  # 确实是非常有用的功能，但是zed不支持，也没有第三方工具可以替代解决该问题
  #
  # - ✅ [Outline for mardown indent] https://github.com/zed-industries/zed/pull/45643
  # v0.220.0 已经处理掉了
  #
  #
  # - [Remote SSH Auto Reconnect]
  # 目前zed不支持 Auto Reconnect，必须要手动重连
  #
  #
  # - []
  # https://github.com/zed-industries/zed/issues/39206

  # MAYBE[2026-01-18]: zed 是否会提供类似 hx --health 这种查看所有本身 xxx  LSP 的命令？
  #
  # https://zed.dev/docs/languages 文档里已经列出了所有langs的LSP

  # https://zed.dev/blog/hidden-gems-part-2
  #
  #
  #
  # - [git commit panel 可以点选并展示单个文件] 而非全部diff统一都全部列在Editor
  # [Single-File Git Diff from Git Panel · zed-industries/zed · Discussion #38420](https://github.com/zed-industries/zed/discussions/38420)
  #
  #

  # 可供参考的zed配置
  # https://github.com/linkfrg/dotfiles/blob/main/modules/home-manager/software/zed/settings.nix
  # https://github.com/pabloagn/rhodium/blob/main/home/apps/ides/zed/default.nix
  # https://github.com/craole-cc/dotDots/blob/main/Admin/Packages/home/zed/settings.nix

  # [2026-01-17] 嵌套写法=dynamic，我需要static，所以直接写死。另外把 theme 从 Catpppuccin -> Monokai
  # theme = {
  #   mode = dark;
  #   # light = One Light;
  #   # Monokai for zed
  #   dark = Monokai-Z;
  # };
  theme = "Monokai-Z";

  # icon_theme = Zed (Default);
  icon_theme = "Catppuccin Mocha";

  # !!!
  # 目前选择了最主流的 jetbrains + vim
  #
  #
  # 默认使用JB的键位
  base_keymap = "JetBrains";
  #
  #
  # https://zed.dev/docs/vim
  #
  vim_mode = true;

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
  };

  # 直接使用stylix的theme
  # [2026-01-12] stylix对GUI的处理有一定偏差，所以禁用了stylix管理，我们手动管理zed的theme
  # UI大小
  # [2026-01-17] 从16调整为15（14太小了）
  ui_font_size = 15;
  # 默认就是 .ZedSans，这里显式声明
  ui_font_family = ".ZedSans";

  # 编辑区字体大
  # [2026-01-18] 13太小 -> 14
  buffer_font_size = 14;

  tab_size = 2;
  preferred_line_length = 120;
  # 换行，按照editor编辑区的可用width自动调整
  soft_wrap = "editor_width";
  buffer_font_family = ".ZedMono";

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

  ############ Search ###########

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

    # 是否在状态栏显示“项目搜索按钮”（不改变范围）
    button = true;
    # 导航匹配时是否居中显示（不改变范围，但影响体验）
    center_on_match = true;
  };

  # 用来给搜索结果 Wrap line
  # 默认true，这里显式声明
  search_wrap = true;

  # 新开搜索时，是否从光标处/选区自动填充查询内容（影响你启动搜索时的“默认范围感”。比如设成 selection 时更偏向“选区驱动”）
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
      EDITOR = "zed --wait";
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

  ##############################
  #
  #
  #

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
  # AI Configuration - Enable Claude Code via ACP
  # Reference: https://zed.dev/blog/claude-code-via-acp
  disable_ai = false;
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
  # MAYBE[2026-01-19](single-file diff view):
  git = {
    git_gutter = "hide";
    inline_blame = {
      enabled = false;
    };
    branch_picker = {
      show_author_name = true;
    };
    hunk_style = "staged_hollow";
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

  # 禁用Tab补全，很干扰
  show_edit_predictions = false;

  # AI Features Configuration
  features = {
    # https://zed.dev/docs/reference/all-settings#edit-prediction-provider
    edit_prediction_provider = "none";
  };

  # hour_format = "hour24";

  # https://zed.dev/docs/configuring-zed#scroll-beyond-last-line
  # 默认 one_page. 在编辑区里，无论什么文件类型，都可以拉到最后一行，导致下面整块全都是一片空白
  # 完全禁用。文件底部将固定在编辑器的底端，无法继续向下滚动。
  scroll_beyond_last_line = "vertical_scroll_margin";

  # https://linux.do/t/topic/929471
  language_models = {
    openai_compatible = {
      glm-open = {
        api_url = "https=//open.bigmodel.cn/api/paas/v4/";
        available_models = [
          {
            name = "glm-4.6";
            display_name = null;
            max_tokens = 128000;
            max_output_tokens = 80000;
            max_completion_tokens = 200000;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = true;
              prompt_cache_key = true;
            };
          }
        ];
      };
    };
  };

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
  # [2026-01-18] 可以看到本身 hm 的 extensions 配置项，也是借用 auto_install_extensions 实现的，二者本身是一码事。所以为啥不用zed本身提供的配置项呢？另外，hm的ext并不支持 auto_update_extensions，所以为了保证一致性和可维护性，我们把相应配置项做个整合
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
    Nix = {
      language_servers = [
        "nil"
      ];
    };

    YAML = {
      # WHAT: 关闭 YAML 的保存时自动格式化（Format on Save）。
      # WHY:
      #   你习惯在注释之间留空行，但很多 formatter（尤其是基于 prettier 风格的 YAML formatter）
      #   会在保存时重排空白行，导致“空行被吞/被合并”。关掉保存自动格式化后，
      #   Zed 不会在保存时替你改文本，你手写的空行能稳定保留。
      format_on_save = "off";
      # WHAT: 关闭“输入时格式化”（on-type formatting）。
      # WHY:
      #   即使你关了保存格式化，有些编辑器仍可能在你输入换行、缩进、补全等过程中触发格式化，
      #   也可能间接引发空白行/注释布局被改写。这里直接关掉，保证“只有你手动 Format 才会改”。
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
      #   - 这里的 "!docker-compose" 不是文件名匹配（不是“compose.yml 才排除”），
      #     它排除的是“语言服务器 ID/名称”。
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
      #   同时你已经把 format_on_save 关掉了，所以这不会影响“保存吞空行”的问题；
      #   它只决定你手动触发 Format 时使用谁来格式化。
      formatter = "language_server";
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
            # 但 Zed 的 LSP 客户端不支持“确认弹窗”，当 inputs 未归档时会反复提示
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
            # WHAT: 设置“打印宽度/换行阈值”为 3000。
            # WHY:
            #   这对应你在 yamllint 里 “line-length max: 3000” 的偏好：
            #   你宁愿保持一行很长，也不希望 formatter 自动折行。
            #   设置很大可以显著减少 formatter 引入的换行 diff。
            printWidth = 3000;
            # WHAT: 控制类似 `{ a: 1 }` / `{a: 1}` 这种“花括号内是否保留空格”的倾向。
            # WHY:
            #   你在其它语言（TS/Prettier）也很在意这类 spacing 一致性。
            #   对 YAML formatter 来说，bracketSpacing=false 通常更“紧凑”，
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
}
