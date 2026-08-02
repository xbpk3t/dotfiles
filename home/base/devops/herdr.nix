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

      packages =
        with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        [
          herdr
        ]
        ++ lib.optionals pkgs.stdenv.isDarwin [
          # herdr-focus-notify：agent blocked/done 时弹 macOS 可点击通知。
          # 依赖 alerter（brew 管理，HERDR_FOCUS_NOTIFY_NOTIFIER 指向 /opt/homebrew/bin/alerter）。
          pkgs.herdr-focus-notify
        ];

      # ——— herdr-focus-notify plugin 声明式接入 ———
      # herdr 无 config.toml 声明 plugin 的机制；plugin 注册状态在 ~/.local/state/herdr/plugins。
      # 这里用 home.activation 幂等注册 nix 版 plugin（herdr plugin link 重复执行安全）。
      # 运行时配置 .env 由 home.file 管理（见下方），指向 alerter 与 Ghostty。
      activation.herdrFocusNotifyPlugin = lib.mkIf pkgs.stdenv.isDarwin (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if command -v herdr >/dev/null 2>&1; then
            herdr plugin link ${pkgs.herdr-focus-notify}/plugin >/dev/null 2>&1 || true
          fi
        ''
      );

      # herdr-focus-notify 运行时配置：激活的终端 app + 通知器路径。
      # 路径是 herdr plugin config-dir herdr-focus-notify 的输出。
      # .env 是 KEY=value 格式 → 用 formats.keyValue 结构化生成（同 config.toml 的 tomlFormat 思路）。
      file.".config/herdr/plugins/config/herdr-focus-notify/.env" = lib.mkIf pkgs.stdenv.isDarwin {
        # 注意：keyValue 不支持注释行（会当 key 解析），说明放 nix 层。
        source = (pkgs.formats.keyValue { }).generate "herdr-focus-notify.env" {
          # 点击通知时激活的终端 app。源码里 app 名走 `open -a <name>`，全路径走 `open <path>`，
          # 两种都支持；用名字更可移植（Ghostty 在 /Applications 或 /opt/homebrew 都能找到）。
          HERDR_FOCUS_NOTIFY_ACTIVATE_APP = "Ghostty";
          # 通知器：alerter 由 brew 管理（nixpkgs 无此包）。
          HERDR_FOCUS_NOTIFY_NOTIFIER = "/opt/homebrew/bin/alerter";
        };
      };

      # 配置路径: ~/.config/herdr/config.toml
      # 结构化 nix → TOML（相同思路参考 pi-agent toJSON）。
      # ⚠️  Nix 注释不会带入生成的 TOML 文件。
      #     运行时用 herdr --default-config 查看完整默认配置。
      file.".config/herdr/config.toml" = {
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
              # Catppuccin blue #89b4fa 叠 mocha base ~32%，清楚但不晃眼
              surface_dim = "#435275";
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
          # 导航键分两层（参考 herdr --default-config 完整键列表）：
          #
          #   direct（无 prefix，高频）：ctrl+alt+letter
          #     [ / ]  Agent 前后切换         u / i  Tab 前后切换
          #     \     回跳上一个 pane          e      新 Tab
          #     t     split right + claude    g      lazygit
          #     d     hunk diff
          #
          #   prefix（ctrl+b + …，中/低频）：
          #     h/j/k/l     pane 方向          x     关 pane
          #     ,/.         prev/next ws       v/−    split
          #     shift+1..9  跳 workspace       c      新 tab（或 ctrl+alt+e）
          #     shift+r     reload config
          #
          # 注释掉的备选 popup（等需要时解开）：
          #   b  btop（原 t 被 split claude 占）  p  ghui PR
          #   l  lazydocker                         y  yazi
          #   k  k9s
          #
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
            # u = ← / i = →（键盘位置直觉）；e = empty = 新 tab
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
                key = "ctrl+alt+t";
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

        }; # source
      };
    };
  };
}
