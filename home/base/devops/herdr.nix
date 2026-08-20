{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.herdr;
  tomlFormat = pkgs.formats.toml { };

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
  # Package: inputs.llm-agents (not brew). Bump the flake input to upgrade;
  # `herdr update` is for curl/brew installs and is a poor fit under HM.
  # Claude session hook lives in home/base/AI/claude.nix + hooks/herdr-agent-state.sh
  # — do not run `herdr integration install claude` against HM-managed settings.json.
  options.modules.devops.herdr = with lib; {
    enable = mkEnableOption "Herdr agent multiplexer (nix package + config.toml)";
  };

  config = lib.mkIf cfg.enable {

    home = {

      # ⚠️ herdr 插件包（herdr-focus-notify / herdr-reviewr）不进 home.packages：
      #   buildEnv 会把每个包的输出合并成一个 tree，两个包都带 plugin/ 目录
      #   （herdr-plugin.toml 在 plugin/ 根），同名 subpath 冲突报错
      #   （"two given paths contain a conflicting subpath"）。
      #   保活不依赖 home.packages：plugins.json 的 ${pkgs.herdr-xxx}/plugin/...
      #   字符串插值已形成 store path context，不会被 GC。
      #   如需脱离 herdr 单跑 reviewr（README 支持），用 nix shell / nix path 拿二进制。
      packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
        herdr
      ];

      # ——— herdr 插件声明式接入 ———
      # ~/.config/herdr/plugins.json 是唯一事实来源，home.file 直接声明生成。
      # 无需 herdr plugin link 命令、无需 activation 脚本（server 启动只读该文件）。
      # plugin 目录本身仍由 home.file 映射（store symlink），与 plugins.json 的
      # manifest_path/plugin_root（nix 相对路径 resolve 到 store）指向同一位置。
      #
      # ⚠️ 声明式纪律：改插件 enable/disable 需改 nix → rebuild；禁止手动跑
      #    herdr plugin install/link/uninstall/enable/disable（会写 store symlink 失败报错）。
      #
      # 生效无需重启：server 每次 plugin list/action list 都从磁盘重读 plugins.json；
      #    reload-config 只重读 config.toml，不碰 plugins.json。
      file = {
        # ——— herdr 插件注册表（声明式） ———
        # ~/.config/herdr/plugins.json 是唯一事实来源：herdr 直接读它，server 启动不重写，无需 link。
        # 每条记录只填必填字段（实测）：plugin_id / manifest_path / plugin_root / enabled / name / version。
        # actions/panes/description/platforms/min_herdr_version/source 非必填 → 不写，
        # herdr 加载时会从 herdr-plugin.toml manifest 重新解析补全。唯一例外：
        #   focus-notify 需要保留 events（通知事件，manifest 不声明，必须显式给出）。
        # 路径写法：本地插件用 nix 相对路径 → 构建时 store 化；focus-notify 用 ${pkgs.herdr-focus-notify}。
        #
        # ⚠️ 声明式纪律：状态仅此一份，改 enable/disable 需改 nix → rebuild；
        #    禁止手动跑 herdr plugin install/link/uninstall/enable/disable（会写 store symlink 失败报错）。
        #    生效无需重启：server 每次 plugin list/action list 都重读本文件。
        ".config/herdr/plugins.json" = {
          force = true;
          # ── 平台条件插件 ──────────────────────────────────────────────
          # focus-notify 是 macOS-only（meta.platforms = aarch64-darwin）：Linux host
          # （如 nixos-vps）启用 herdr 时注册它会让 `nix flake check` 的 host-eval
          # 在跨架构求值时报「包不支持当前 platform」。故仅 darwin 时并入数组。
          # ───────────────────────────────────────────────────────────────
          text = builtins.toJSON (
            [
              {
                plugin_id = "jt.command-palette";
                name = "Command Palette";
                version = "0.1.0";
                manifest_path = "${toString ./herdr/herdr-plugins-palette}/herdr-plugin.toml";
                plugin_root = toString ./herdr/herdr-plugins-palette;
                enabled = true;
              }
              {
                plugin_id = "persiyanov.reviewr";
                name = "Reviewr";
                version = "0.29.0";
                # store 插件：manifest_path/plugin_root 用 ${pkgs.herdr-reviewr} 绝对路径。
                # manifest 里 pane command 是 $HERDR_PLUGIN_ROOT/bin/herdr-reviewr（server 打开
                # pane 时注入 HERDR_PLUGIN_ROOT），actions/events 相对路径 bash herdr/pane.sh
                # 的 cwd = plugin_root —— 两条都原样保留，不要改成绝对 store 路径（rebuild 会变）。
                manifest_path = "${pkgs.herdr-reviewr}/plugin/herdr-plugin.toml";
                plugin_root = "${pkgs.herdr-reviewr}/plugin";
                enabled = true;
                # NOTE: events（worktree.created 自动 open）已在上游 herdr-plugin.toml 声明，
                # herdr 加载时从 manifest 重新解析补全 → 这里不重复写。
                # 对比 focus-notify：它的 events 是 nix 侧手写 manifest 里才有的
                # （上游不持有），所以才需要显式给出。
              }
            ]
            # focus-notify 是 macOS-only（meta.platforms = aarch64-darwin）：Linux
            # host（如 nixos-vps）启用 herdr 时不注册，否则 `nix flake check` 的
            # host-eval 会在跨架构求值时因「包不支持当前 platform」失败。
            ++ lib.optional pkgs.stdenv.isDarwin {
              plugin_id = "herdr-focus-notify";
              name = "Herdr Focus Notify";
              version = "0.3.6";
              manifest_path = "${pkgs.herdr-focus-notify}/plugin/herdr-plugin.toml";
              plugin_root = "${pkgs.herdr-focus-notify}/plugin";
              enabled = true;
              # focus-notify 的通知事件（非必填但本插件需要，manifest 不持有）
              events = [
                {
                  on = "pane.agent_status_changed";
                  command = [ "${pkgs.herdr-focus-notify}/bin/herdr-focus-notify" ];
                }
                {
                  on = "pane.focused";
                  command = [ "${pkgs.herdr-focus-notify}/bin/herdr-focus-notify" ];
                }
              ];
            }
          );
        };

        # ——— 本地插件目录映射 ———
        # 每个插件一个子目录 (含 herdr-plugin.toml + 脚本), 整目录映射到
        # ~/.config/herdr/plugins/<name>/。manifest_path 靠 nix 相对路径 resolve 到 store。
        ".config/herdr/plugins/herdr-plugins-palette" = {
          source = ./herdr/herdr-plugins-palette;
          force = true;
        };

        # herdr-focus-notify 运行时配置：激活的终端 app + 通知器路径。
        # 路径是 herdr plugin config-dir herdr-focus-notify 的输出。
        # .env 是 KEY=value 格式 → 用 formats.keyValue 结构化生成（同 config.toml 的 tomlFormat 思路）。
        ".config/herdr/plugins/config/herdr-focus-notify/.env" = lib.mkIf pkgs.stdenv.isDarwin {
          # 注意：keyValue 不支持注释行（会当 key 解析），说明放 nix 层。
          source = (pkgs.formats.keyValue { }).generate "herdr-focus-notify.env" {
            # 点击通知时激活的终端 app。源码里 app 名走 `open -a <name>`，全路径走 `open <path>`，
            # 两种都支持；用名字更可移植（Ghostty 在 /Applications 或 /opt/homebrew 都能找到）。
            HERDR_FOCUS_NOTIFY_ACTIVATE_APP = "Ghostty";
            # 通知器：alerter 由 brew 管理（nixpkgs 无此包）。
            HERDR_FOCUS_NOTIFY_NOTIFIER = "/opt/homebrew/bin/alerter";
          };
        };

        ".config/herdr/plugins/config/persiyanov.reviewr/config.toml" = {
          force = true;
          source = tomlFormat.generate "herdr-reviewr-config.toml" {
            # popup
            toggle_placement = "overlay";
            # 关掉 worktree.created 自动 open：overlay 不被 auto-open 支持（README：
            # "New worktrees auto-open only split and tab"），且手动 toggle 才符合 popup 预期。
            auto_open = false;
            # 其余 key 用默认：
            #   theme / base_branches / default_scope / navigator_position / toggle_direction
            #   github_host / [keybindings] —— 需要的再补，别加未知 key（会整文件无效）。
          };
        };

        # 配置路径: ~/.config/herdr/config.toml
        # 结构化 nix → TOML（相同思路参考 pi-agent toJSON）。
        # ⚠️  Nix 注释不会带入生成的 TOML 文件。
        #     运行时用 herdr --default-config 查看完整默认配置。
        ".config/herdr/config.toml" = {
          force = true;

          # 如需在生成的 TOML 里嵌入注释：
          #   可以把 attrset 转 JSON → 注入 # 注释行 → 再转 TOML。
          # 当前约定用结构化 attrset，nix 层注释说明设计意图。
          source = tomlFormat.generate "herdr-config.toml" {

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
              # 屏蔽"有新版本"噪音 — 真正升级靠 bump llm-agents flake input
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
              # （见上方 home.activation / .env 配置），herdr 内建 system 路径不用。
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
      };
    };
  };
}
