{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.desktop.ghostty;
  cmuxCfg = config.modules.desktop.cmux;

  ghosttySettings = {
    # ── Scrollback ──────────────────────────────────────────────────
    # 滚动缓冲区行数。agent 输出较长时保证能回滚查看。
    scrollback-limit = 10000;

    # ── Window ──────────────────────────────────────────────────────
    # 关闭窗口时不确认。tmux/cmux 场景下避免频繁弹窗。
    confirm-close-surface = false;

    # 背景透明度 (0.0~1.0)。用 string 避免 toString float 产生尾随零。
    # [2026-05-20] 背景透明度。1 = 完全不透明；低于 1 会让 cmux/ghostty terminal 背景透明。
    background-opacity = "1";
    # 禁用背景模糊；避免未来不小心把 opacity 调低后出现毛玻璃。
    background-blur = false;
    # 禁用非焦点 split pane 的淡化效果。
    unfocused-split-opacity = "1";

    # 窗口左右内边距（px）。避免文字紧贴窗口边缘。
    window-padding-x = 4;

    # ── macOS Tab ──────────────────────────────────────────────────
    # macOS 原生 tab bar 显示在窗口左侧，视觉上接近 IDE 侧栏风格。
    # 替代默认的顶部 tab 条，多 tab 场景下更易读。
    # 选项: left | bottom | hidden
    macos-tab-sidebar = "left";

    # ── Clipboard ───────────────────────────────────────────────────
    # 允许应用读取/写入/粘贴系统剪贴板。
    clipboard-read = "allow";
    clipboard-write = "allow";

    # 选中文本自动复制到系统剪贴板，而非仅选区（primary selection）。
    copy-on-select = "clipboard";

    # ── Cursor ──────────────────────────────────────────────────────
    # 光标样式：bar（竖线）| block（方块）| underline（下划线）。
    cursor-style = "bar";

    # 光标闪烁，便于在多 pane 场景下快速定位焦点。
    cursor-style-blink = true;

    # ── Quick Terminal ────────────────────────────────────────────
    # Quick terminal 是全局浮层终端（Quake-style dropdown），
    # 按快捷键时从屏幕边缘弹出，适合快速敲命令后消失。
    # 独立于 cmux 运行，作为 cmux agent cockpit 的"副终端"。
    # https://ghostty.org/docs/config/reference#quick-terminal-position
    quick-terminal-position = "right";
    quick-terminal-size = "0.35";
    quick-terminal-screen = "main";
    quick-terminal-auto-hide = true;

    # ── 待定（注释掉供参考）─────────────────────────────────────────
    # background = "black";
    # window-padding-color = "background";
    # font-family = "0xProto";
    # font-size = 10;
    # mouse-hide-while-typing = true;
    # auto-update = "off";
    # gtk-titlebar = false;
    # shell-integration = "none";
    # linux-cgroup = "always";
    # resize-overlay = "never";

    # ── Keybind ─────────────────────────────────────────────────────
    # NOTE(ghostty): not using ghostty for splits or tabs so nearly
    # all default binds conflict Hypr, nvim, or zellij.
    keybind = [
      # ── 调试 ──
      "ctrl+shift+d=inspector:toggle"

      # ── 剪贴板 ──
      "ctrl+shift+c=copy_to_clipboard"
      "ctrl+shift+v=paste_from_clipboard"

      # 修复 fixterm 与 zsh ^[ 的冲突
      # https://github.com/ghostty-org/ghostty/discussions/5071
      "ctrl+left_bracket=text:\\x1b"

      # ── 字号 ──
      "ctrl+shift+minus=decrease_font_size:1"
      "ctrl+shift+plus=increase_font_size:1"
      "ctrl+shift+0=reset_font_size"

      # ── Quick Terminal ──
      "super+grave_accent=toggle_quick_terminal"

      # ── 屏蔽默认快捷键（与 tmux/zellij 冲突）────────────────────
      "ctrl+shift+e=unbind" # new_split   → 被 tmux split 取代
      "ctrl+shift+n=unbind" # new_window  → 由 tmux/zellij 管理
      "ctrl+shift+t=unbind" # new_tab     → 由 tmux/zellij 管理
    ];

  };
in
{
  options.modules.desktop.ghostty = {
    enable = mkEnableOption "ghostty terminal";
  };

  # [2026-01-22] [Scrolling issues · ghostty-org/ghostty · Discussion #7630](https://github.com/ghostty-org/ghostty/discussions/7630) 本地多次触发类似问题，本想换到其他Terminal，但是这个issue在其他terminal也是存在的，所以作罢。
  #
  # why?
  #
  # ***偶发进入 alternate screen（备用屏） 后，备用屏没有 scrollback，Ghostty（以及很多终端）会把"滚轮滚动"翻译成"↑/↓"来"让不支持鼠标的 TUI 也能滚动/导航"，结果在 shell 里就变成"翻历史/触发 atuin"。***
  #
  #
  #
  #
  # 那其他terminal是否会遇到类似问题？
  #
  # 这类问题不是 Ghostty 独有，而是"终端生态里一个很常见的交互坑"，只是在不同 terminal 上触发条件/表现/可配置项不一样。
  # - 有的终端明确提供开关：比如 iTerm2 有"滚轮在 alternate screen 时发送方向键"的选项，开了就很容易出现你这种现象。
  # - 有的终端默认更"保守"：比如 kitty 通常更倾向于保持滚轮是滚动 scrollback（除非进入某些鼠标报告模式/你自己做了 mouse_map），所以更不容易踩到"滚轮=↑"。
  # - 有的终端遇到备用屏会更激进地"把滚轮喂给应用"：这样 TUI 的滚动体验更统一，但一旦状态没退出干净，就会在 shell 里造成"滚轮变按键"。
  #
  #
  #
  #
  # htu?
  # 在ghostty执行Reset操作（重置终端状态，常用于退出卡住的 alternate screen 状态）

  # ghostty 或 cmux 任一启用即可触发 Ghostty 配置部署：
  #   - macOS: brew 管理 Ghostty.app，Nix 管理配置文件（供 cmux 共享）
  #   - Linux: programs.ghostty 完整管理（包 + 配置 + shell 集成）
  config = mkIf (cfg.enable || (cmuxCfg.enable && pkgs.stdenv.isDarwin)) (mkMerge [
    # ─── macOS ──────────────────────────────────────────────
    # Ghostty 配置格式为 key=value（类似 env），直接用 generators.toKeyValue 渲染。
    # cmux (libghostty) 也读取同一份配置，见 cmux.nix。
    (mkIf pkgs.stdenv.isDarwin {
      #
      # !!! macOS 上 nixpkgs 的 ghostty 包不受支持，通过 Brew Cask 安装。
      #     但配置文件通过 Nix 统一管理（ghostty 和 cmux 共享）。
      xdg.configFile."ghostty/config" = {
        force = true;
        text = generators.toKeyValue {
          listsAsDuplicateKeys = true;
        } ghosttySettings;
      };
    })

    # ─── Linux ──────────────────────────────────────────────
    # Nixpkgs 支持 Linux 上直接管理 Ghostty 包。
    # programs.ghostty.settings 自动写入 ~/.config/ghostty/config。
    (mkIf pkgs.stdenv.isLinux {
      programs.ghostty = {
        # https://github.com/NixOS/nixpkgs/issues/388984
        enable = true;
        package = pkgs.ghostty;
        installVimSyntax = true;
        installBatSyntax = true;
        enableZshIntegration = true;
        settings = ghosttySettings;
      };
    })
  ]);
}
