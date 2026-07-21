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
          toast = {
            delivery = "system";
            delay_seconds = 1; # 防抖：状态持续 1s 后才弹通知
          };
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
