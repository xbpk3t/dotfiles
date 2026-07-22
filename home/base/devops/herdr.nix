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

    home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      herdr
    ];

    # 配置路径: ~/.config/herdr/config.toml
    # 结构化 nix → TOML（相同思路参考 pi-agent toJSON）。
    # ⚠️  Nix 注释不会带入生成的 TOML 文件。
    #     运行时用 herdr --default-config 查看完整默认配置。
    home.file.".config/herdr/config.toml" = {
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

          # ——— 通知：macOS 通知中心 ———
          # "system"   → OS 原生（macOS Notification Center）
          # "herdr"    → TUI 内弹条
          # "terminal" → 委托外层终端（Ghostty）弹通知
          # "off"      → 关闭
          # mouse_capture 保持默认 true：Cmd-click 开 URL 需 false，但会丢掉 herdr 鼠标 UI
          toast = {
            delivery = "system";
            delay_seconds = 1; # 防抖：状态持续 1s 后才弹通知
          };
        };

        # ——— 键位 / 自定义命令 ———
        # 不用 workspace 的 omp/ghui 四格插件；agent cockpit 工具层全用 popup（A 除外）：
        #   A: 当前 pane 右侧再开一格 claude
        #   G: lazygit（stage/commit）
        #   D: hunk diff（review-first；包+配置见 hunk.nix）
        #   P: ghui PR（包+配置见 ghui.nix）
        #   L: lazydocker（colima/compose；core/ms/lazydocker.nix）
        #   Y: yazi（文件浏览；勿用 yy shell wrapper，popup 改不了外层 cwd）
        #   T: btop（资源）
        #   K: k9s（集群）
        #
        # 修饰：ctrl+alt+letter（无 prefix，一击）。
        # macOS 上 alt = Option 键；herdr/ghostty 配置里写 alt，物理键是 ⌥。
        # 不用 ctrl+shift：那是 Ghostty chrome 带（c/v 剪贴板、字号、inspector）。
        # herdr 文档示例也把 ctrl+alt+n 标成 direct terminal-mode shortcut。
        # 残留风险：少数 IME/终端对 Option 组合键吞键 → 整层改 prefix+alt。
        keys = {
          command = [
            {
              key = "ctrl+alt+a";
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
            {
              key = "ctrl+alt+p";
              type = "popup";
              description = "ghui PR dashboard";
              command = "ghui";
              width = "90%";
              height = "90%";
            }
            {
              key = "ctrl+alt+l";
              type = "popup";
              description = "lazydocker floating popup";
              command = "lazydocker";
              width = "90%";
              height = "90%";
            }
            {
              key = "ctrl+alt+y";
              type = "popup";
              description = "yazi file manager";
              command = "yazi";
              width = "90%";
              height = "90%";
            }
            {
              key = "ctrl+alt+t";
              type = "popup";
              description = "btop resource monitor";
              command = "btop";
              width = "90%";
              height = "90%";
            }
            {
              key = "ctrl+alt+k";
              type = "popup";
              description = "k9s kubernetes dashboard";
              command = "k9s";
              width = "90%";
              height = "90%";
            }
          ];
        };

        # ——— 实验特性 ———
        experimental = {
          pane_history = false;

          # macOS 上 Claude 隐藏光标时，修复 IME 候选窗口不跟随的问题。
          # 副作用：vim 普通模式下会多一个光标。
          reveal_hidden_cursor_for_cjk_ime = true;
          cjk_ime_agents = [ "claude" ];
        };

      }; # source
    };
  };
}
