{
  config,
  herdrPlugins,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.herdr;

  # ——— sidebar agent 行配色：文字显式提亮到可读对比度 ———
  # 背景：catppuccin 暗字层(overlay)在抬高的选中行底色上只有 ~2:1，读不清。
  #   首行 tab（pane 名）：text #cdd6f4 + bold    → base 11.3:1 / 选中行 5.4:1
  #   terminal_title_stripped（任务名）：subtext1 #bac2de → 9.3 / 4.4 :1
  #   agent（类型）：subtext0 #a6adc8              → 7.4 / 3.5 :1
  sidebarAgentRows = [
    [
      "state_icon"
      {
        token = "tab";
        fg = "#cdd6f4";
        bold = true;
      }
    ]
    [
      {
        token = "agent";
        fg = "#a6adc8";
      }
    ]
  ];
  sidebarAgentRowsTitle = [
    [
      "state_icon"
      {
        token = "tab";
        fg = "#cdd6f4";
        bold = true;
      }
    ]
    [
      {
        token = "terminal_title_stripped";
        fg = "#bac2de";
      }
    ]
    [
      {
        token = "agent";
        fg = "#a6adc8";
      }
    ]
  ];
in
{
  # host:
  #   modules.devops.herdr.enable = true;
  #
  # Package: inputs.herdr-bin（官方预编译二进制，0.9.5）。
  # Config: 官方 Home Manager `programs.herdr.settings` → ~/.config/herdr/config.toml。
  # Plugins: inputs.herdr-nix（lorenzorapetti/herdr-nix）模块；activation 里用
  #   `herdr plugin link` 注册，~/.config/herdr/plugins.json 不再由 HM 手写。
  #   改插件列表改 Nix → rebuild；禁止手动 herdr plugin install/link/uninstall/enable/disable。
  # Annotate（herdr-annotate，full）：终端文本/文档/agent 回复注释并回灌给 agent，
  #   键位 prefix+a/m/o 等见下方 keys.command；full 含 plannotator-tui 文档审阅。
  # Claude session hook lives in home/base/AI/claude.nix + hooks/herdr-agent-state.sh
  # — do not run `herdr integration install claude` against HM-managed settings.json.
  options.modules.devops.herdr = with lib; {
    enable = mkEnableOption "Herdr agent multiplexer (nix package + config.toml + plugins)";
  };

  config = lib.mkIf cfg.enable {
    programs.herdr = {
      enable = true;

      # 官方预编译二进制（0.9.5）。reviewr 0.47 要求 herdr >= 0.9.3；
      # 升级用 `nix flake update herdr-bin`，不要用 `herdr update`。
      package = inputs.herdr-bin.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # 插件注册由 herdr-nix 模块负责（activation 里 `herdr plugin link`）。
      # focus-notify 是 macOS-only；Linux host 上不注册。
      plugins = [
        # [2026-10-23] 暂时停用：plannotator-tui 的测试在含非 ASCII 字符的路径下
        # rustc 链接失败（ld: file not found: $.../ü...），导致 deploy 构建失败。
        # upstream: https://github.com/lorenzorapetti/herdr-nix/issues/4 (plannotator-tui 构建)
        # 修复后恢复此行，并同步恢复下方 annotate.* 键位。
        # herdrPlugins.herdr-annotate-full
        herdrPlugins.herdr-reviewr
        herdrPlugins.herdr-web-ui
        ./herdr/herdr-plugins-palette
      ]
      ++ lib.optional pkgs.stdenv.isDarwin pkgs.herdr-focus-notify;

      # reviewr 配置写入 ~/.config/herdr/plugins/config/persiyanov.reviewr/config.toml
      pluginSettings."persiyanov.reviewr" = {
        # popup
        toggle_placement = "overlay";
        # 关掉 worktree.created 自动 open：overlay 不被 auto-open 支持（README：
        # "New worktrees auto-open only split and tab"），且手动 toggle 才符合 popup 预期。
        auto_open = false;
      };

      # 配置路径: ~/.config/herdr/config.toml（官方 HM 模块生成）
      # ⚠️  Nix 注释不会带入生成的 TOML 文件。
      #     运行时用 herdr --default-config 查看完整默认配置。
      settings = {
        # ——— 通用 ———（完整默认配置：herdr --default-config）
        onboarding = false;

        theme = {
          # herdr 默认用 catppuccin，这里显式声明
          name = "catppuccin";
          # pane/边框 accent 与选中行底色分开，避免只拧 accent 时左侧 spaces/agents 看不出变化。
          custom = {
            # pane 边框 / 导航高亮（mauve）
            accent = "#f5c2e7";
            # sidebar spaces/agents 当前选中行底色：
            # 压暗一档 #3b4a6b（原 #435275 上暗字 ~2:1 读不清），给 sidebar 文字留对比度余量
            surface_dim = "#3b4a6b";
          };
        };

        # ——— 终端 ———
        terminal = {
          shell_mode = "auto"; # macOS 走 login shell 以确保 Homebrew PATH
          new_cwd = "follow"; # 新 pane 继承来源 pane/workpace 的 cwd
        };

        # ——— 会话 / Agent 恢复 ———
        session = {
          # 服务重启后恢复 Claude 会话（需 SessionStart hook 配合）
          resume_agents_on_restore = true;
        };

        # ——— 更新（nix 管理） ———
        update = {
          # 屏蔽"有新版本"噪音 — 真正升级靠 bump herdr-bin flake input
          version_check = false;
        };

        # ——— UI ———
        ui = {
          sidebar_width = 22;
          sidebar_min_width = 16;
          sidebar_max_width = 36;
          prompt_new_tab_name = false;

          # 与 theme.custom.accent 对齐（pane / borders / navigation）
          accent = "#f5c2e7";

          # 误关 workspace 前弹出确认，避免顺手杀 agent pane（对标 cmux warnBeforeClosingTab）
          confirm_close = true;

          # 切回 herdr 时减少整屏闪烁
          redraw_on_focus_gained = false;

          # 分屏边框显示 agent 名字（如 "claude"），方便识别
          show_agent_labels_on_pane_borders = true;

          # Agents 列表按 workspace 顺序排列
          agent_panel_sort = "spaces";

          # 侧栏 agents：首行 = pane/tab 名（手动 prefix+shift+t 改名）。
          # 会写 OSC 终端标题的主流 agent（claude/codex/grok，herdr 探测配置用 osc_title 佐证）
          # 额外一行 terminal_title_stripped：自动显示任务名/ai-title（无则显示兜底标题）。
          # opencode/gemini/pi/cursor/copilot 不写 OSC 标题 → 走通用 rows，不加。
          sidebar = {
            agents = {
              rows = sidebarAgentRows;
              rows_by_agent = {
                claude = sidebarAgentRowsTitle;
                codex = sidebarAgentRowsTitle;
                grok = sidebarAgentRowsTitle;
              };
            };
          };

          # mouse_capture = true（默认）保持 herdr 鼠标 UI。
          # 尝试 false 后确认不可用：选中复制(copy_on_select)依赖 mouse capture 创建 selection，
          # 且滚轮会被终端拦截为 ↑/↓，Claude 收 ↑/↓ 翻历史而非翻 pane scrollback。
          # 全键盘驱动不受 sidebar/tab 点击影响；Cmd-Click URL 用 prefix+[ 复制模式替代。
          mouse_capture = true;

          # ——— 通知 ———
          # "herdr"    → TUI 内弹条（macOS 也用这个：桌面通知交给 herdr-focus-notify plugin）
          # "terminal" → 委托外层终端（Ghostty）弹通知
          # "system"   → OS 原生（⚠️ 已弃用：terminal-notifier 在 macOS 15.6 挂起）
          # "off"      → 关闭
          # [2026-08-02] macOS 桌面通知由 herdr-focus-notify plugin + alerter 承担
          # （.env 配置见下方 herdr-focus-notify 段落），herdr 内建 system 路径不用。
          # 用 herdr 内建 toast 做 TUI 内提示，避免重复弹 + 避免 terminal-notifier 挂起。
          toast = {
            delivery = "herdr";
            delay_seconds = 1; # 防抖：状态持续 1s 后才弹通知
          };
        };

        # ——— 键位 / 自定义命令 ———
        # 修饰：ctrl+alt+letter（无 prefix，一击）。
        # macOS 上 alt = Option 键；herdr/ghostty 配置里写 alt，物理键是 ⌥。
        # 不用 ctrl+shift：那是 Ghostty chrome 带（c/v 剪贴板、字号、inspector）。
        # herdr 文档示例也把 ctrl+alt+n 标成 direct terminal-mode shortcut。
        # 残留风险：少数 IME/终端对 Option 组合键吞键 → 整层改 prefix+alt。
        keys = {
          # ——— Agent 导航（高频 → direct key，无 prefix） ———
          # `[` / `]` 直觉对应后退/前进；和 Ghostty ctrl+left_bracket 不冲突
          previous_agent = "ctrl+alt+[";
          next_agent = "ctrl+alt+]";

          # ——— Tab 导航（高频 → direct key） ———
          # u = ← / i = →（键盘位置直觉）；e `= empty = 新 tab
          previous_tab = "ctrl+alt+u";
          next_tab = "ctrl+alt+i";
          new_tab = "ctrl+alt+e";

          # ——— Pane 跳转 ———
          # 回跳到上一个活跃 pane（反斜杠 = "跳转"隐喻）
          last_pane = "ctrl+alt+\\";

          # ——— Workspace 切换（中频 → prefix 层） ———
          # comma/period = 后退/前进（物理键位直觉）
          previous_workspace = "prefix+comma";
          next_workspace = "prefix+period";
          # shift+1..9 区别于 tab 的 1..9
          switch_workspace = "prefix+shift+1..9";

          # ——— 自定义命令（popup / shell） ———
          command = [
            {
              key = "ctrl+alt+p";
              type = "shell";
              description = "split right and run claude (cwd follows source pane)";
              # pane split 无「创建即 run」；先 split 拿 pane_id，再 pane run。
              # 必须解析 .result.pane.pane_id（勿 grep 裸 "id"，会撞到 envelope 的 cli:pane:split）。
              command = ''
                B="''${HERDR_BIN_PATH:-herdr}"
                out=$("$B" pane split --current --direction right --focus)
                pid=$(printf '%s' "$out" | jq -r '.result.pane.pane_id // empty')
                [ -n "$pid" ] && "$B" pane run "$pid" claude
              '';
            }
            {
              # 内置 scratch terminal：临时操作弹窗（官方文档示例写法）。
              # 命令退出即消失；不持久会话——需要持久再上 herdr-floax 插件。
              key = "ctrl+alt+t";
              type = "popup";
              description = "scratch terminal (popup shell)";
              command = "exec \"\${SHELL:-sh}\"";
              width = "80%";
              height = "80%";
            }
            {
              key = "ctrl+alt+g";
              type = "popup";
              description = "lazygit floating popup";
              command = "lazygit";
              width = "90%";
              height = "90%";
            }
            {
              key = "ctrl+alt+d";
              type = "popup";
              description = "hunk diff . (review working tree)";
              command = "hunk diff .";
              width = "90%";
              height = "90%";
            }

            {
              key = "prefix+p";
              type = "plugin_action";
              description = "Command palette (全部插件 action, fzf)";
              command = "jt.command-palette.open";
            }
            {
              # reviewr 官方 README 建议 cmd+r，但 herdr 键位体系只有 ctrl/alt/prefix
              # （cmd/⌘ 不是 herdr 的 key 修饰符）→ 落地 ctrl+alt+r，保留 r=review 语义。
              # direct 层与 ctrl+alt+t/g/d 同构；prefix 层已满（shift+r 是 reload config）。
              key = "ctrl+alt+r";
              type = "plugin_action";
              description = "Reviewr — open code review pane (toggle)";
              command = "persiyanov.reviewr.toggle";
            }
            # ——— Annotate（plannotator/herdr-annotate，full）———— [暂时停用]
            # 终端文本注释 + 文档/agent 回复审阅，反馈回灌给 agent。
            # 键位均为 prefix 层，与现有 prefix+comma/period/shift+1..9/p 不冲突。
            # 注释顺序即 agent 读到反馈的顺序（Annotation N + Comment on: 引用原文）。
            # 插件本身因 plannotator-tui 构建失败已从 plugins 移除，恢复插件后一并恢复。
            # {
            #   key = "prefix+a";
            #   type = "plugin_action";
            #   description = "Annotate — comment on selected text";
            #   command = "annotate.capture";
            # }
            # {
            #   key = "prefix+m";
            #   type = "plugin_action";
            #   description = "Annotate — manage annotations (copy/send/archive)";
            #   command = "annotate.manage";
            # }
            # {
            #   key = "prefix+o";
            #   type = "plugin_action";
            #   description = "Annotate — review documents in this folder";
            #   command = "annotate.open";
            # }
            # {
            #   key = "prefix+shift+o";
            #   type = "plugin_action";
            #   description = "Annotate — review agent's last reply";
            #   command = "annotate.last";
            # }
            # {
            #   key = "prefix+ctrl+s";
            #   type = "plugin_action";
            #   description = "Annotate — send annotations to agent (next message) & archive";
            #   command = "annotate.send-archive";
            # }
            # {
            #   key = "ctrl+alt+p";
            #   type = "popup";
            #   description = "ghui PR dashboard";
            #   command = "ghui";
            #   width = "90%";
            #   height = "90%";
            # }
            # {
            #   key = "ctrl+alt+l";
            #   type = "popup";
            #   description = "lazydocker floating popup";
            #   command = "lazydocker";
            #   width = "90%";
            #   height = "90%";
            # }
            # {
            #   key = "ctrl+alt+y";
            #   type = "popup";
            #   description = "yazi file manager";
            #   command = "yazi";
            #   width = "90%";
            #   height = "90%";
            # }
            # {
            #   key = "ctrl+alt+b";
            #   type = "popup";
            #   description = "btop resource monitor (ctrl+alt+t 被 split claude 占用，改 b)";
            #   command = "btop";
            #   width = "90%";
            #   height = "90%";
            # }
            # {
            #   key = "ctrl+alt+k";
            #   type = "popup";
            #   description = "k9s kubernetes dashboard";
            #   command = "k9s";
            #   width = "90%";
            #   height = "90%";
            # }
          ];
        };

        # ——— 实验特性 ———
        experimental = {
          pane_history = false;

          # macOS 上 Claude 隐藏光标时，修复 IME 候选窗口不跟随的问题。
          # 副作用：vim 普通模式下会多一个光标。
          # Linux / remote server 无本机 IME 候选窗，关掉避免无意义副作用。
          reveal_hidden_cursor_for_cjk_ime = pkgs.stdenv.isDarwin;
          cjk_ime_agents = lib.optionals pkgs.stdenv.isDarwin [ "claude" ];
        };
      };
    };

    # 迁移保护：旧配置把 ~/.config/herdr/plugins.json 管成 store symlink，
    # 而 herdr-nix 的 activation 用 `herdr plugin link` 写真实文件。首次 rebuild 时
    # 先移除旧 symlink，避免 link 尝试写只读 store（失败是静默的）。
    home.activation.removeLegacyHerdrPluginsJson = lib.hm.dag.entryBefore [ "herdrPlugins" ] ''
      if [ -L "$HOME/.config/herdr/plugins.json" ]; then
        rm -f "$HOME/.config/herdr/plugins.json"
      fi
    '';

    # herdr-focus-notify 运行时配置：激活的终端 app + 通知器路径。
    # 路径是 herdr plugin config-dir herdr-focus-notify 的输出。
    # .env 是 KEY=value 格式 → 用 formats.keyValue 结构化生成。
    # 用 xdg.configFile 而非 home.file：herdr-nix 模块对 json/toml/yaml 之外的
    # 插件配置（如本 .env）明确文档化此逃生舱，且 $XDG_CONFIG_HOME 路径本仓统一走它。
    xdg.configFile."herdr/plugins/config/herdr-focus-notify/.env" = lib.mkIf pkgs.stdenv.isDarwin {
      # 注意：keyValue 不支持注释行（会当 key 解析），说明放 nix 层。
      force = true;
      source = (pkgs.formats.keyValue { }).generate "herdr-focus-notify.env" {
        # 点击通知时激活的终端 app。源码里 app 名走 `open -a <name>`，全路径走 `open <path>`，
        # 两种都支持；用名字更可移植（Ghostty 在 /Applications 或 /opt/homebrew 都能找到）。
        HERDR_FOCUS_NOTIFY_ACTIVATE_APP = "Ghostty";
        # 通知器：alerter 由 brew 管理（nixpkgs 无此包）。
        HERDR_FOCUS_NOTIFY_NOTIFIER = "/opt/homebrew/bin/alerter";
      };
    };
  };
}
