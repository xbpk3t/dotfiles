{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  isDarwin = pkgs.stdenv.isDarwin;
  cfg = config.modules.devops.tmux;
in {
  options.modules.devops.tmux = {
    agentSidebar = {
      enable = mkEnableOption "tmux-agent-sidebar integration";
    };
  };

  # ──────────────────────────────────────────────
  #  tmux: terminal multiplexer
  #  目标：替代 cmux 的 "agent cockpit" 角色，
  #  配合 tmux-agent-sidebar 管理 Claude Code 会话。
  #  Zellij (zz) 不受影响，仍然可用。
  # ──────────────────────────────────────────────

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      # 保持默认 prefix (C-b)，避免与 readline C-a（行首跳转）冲突
      prefix = "C-b";
      mouse = true;
      keyMode = "vi";

      # 大 scrollback，方便查看 agent 输出
      historyLimit = 100000;

      # 减少 Esc 延迟
      escapeTime = 10;

      # 起始索引从 1 开始，方便键盘选择
      baseIndex = 1;

      # attach 时若无 session 则自动创建
      newSession = true;

      # 现代终端兼容
      terminal = "tmux-256color";
      focusEvents = true;

      extraConfig = ''
        ##### Core tmux ergonomics #####

        # 关闭窗口时自动重编号
        set -g renumber-windows on

        # 自动命名 pane/window
        set -g automatic-rename on
        set -g set-titles on

        ##### Zellij-style Alt navigation #####
        # 直接 Alt+h/j/k/l 切换 pane，不需要 prefix。
        # 与 zz (Zellij) 的 Alt+h/j/k/l 操作一致。
        # 注意：GoLand Terminal 需开启 Override IDE shortcuts 才不吞 Alt。

        bind -n M-h select-pane -L
        bind -n M-j select-pane -D
        bind -n M-k select-pane -U
        bind -n M-l select-pane -R
        bind -n M-n new-window

        ##### Top status bar — tab 式体验 #####

        # 状态栏放顶部，更像 IDE tab
        set -g status-position top
        set -g status-interval 2
        set -g status-left-length 50
        set -g status-left '#[fg=cyan][#S] '
        set -g window-status-format ' #I:#W '
        set -g window-status-current-format '#[reverse] #I:#W #[default]'

        ##### Terminal compatibility #####

        # 放行 passthrough 转义序列，tmux-agent-sidebar 的 overlay 依赖此特性
        set -g allow-passthrough on

        # True color 支持
        set -as terminal-overrides ',xterm-ghostty:RGB'
        set -as terminal-overrides ',xterm-256color:RGB'
        set -as terminal-overrides ',screen-256color:RGB'
        set -as terminal-overrides ',tmux-256color:RGB'

        ##### TPM #####

        set -g @plugin 'tmux-plugins/tpm'

        # 状态通知（macOS 用 osascript，Linux 需 notify-send + libnotify）
        ${optionalString isDarwin ''
          set -g @tpm-notify-script 'osascript -e "display notification \"#{plugin_name} installed\" with title \"Tmux Plugins\""'
        ''}

        ${optionalString cfg.agentSidebar.enable ''
          ##### tmux-agent-sidebar #####
          # 窄 sidebar（按百分比）
          set -g @sidebar_width '10%'

          # 隐藏底部 Activity/Git 面板
          set -g @sidebar_bottom_height '0'

          # 不自动创建 sidebar——用户按需用 C-b e 打开
          set -g @sidebar_auto_create 'off'

          # 桌面通知保持开启
          set -g @sidebar_notifications 'on'

          # 只关注 agent 关键事件，task_completed 默认关闭
          set -g @sidebar_notifications_events 'stop,notification,stop_failure'

          set -g @plugin 'hiroppy/tmux-agent-sidebar'
        ''}

        # TPM 启动（必须保持在最后一行）
        run '~/.tmux/plugins/tpm/tpm'
      '';
    };

    # TPM 引导——首次运行或更新时克隆/拉取
    # 跟随 home/darwin/default-apps.nix 中 home.activation.setDefaultApps 的先例模式
    home.activation.installTpm = lib.hm.dag.entryAfter ["writeBoundary"] ''
      TPM_DIR="$HOME/.tmux/plugins/tpm"
      if [ ! -d "$TPM_DIR/.git" ]; then
        $VERBOSE_ECHO "Cloning TPM..."
        mkdir -p "$HOME/.tmux/plugins"
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
      else
        $VERBOSE_ECHO "Updating TPM..."
        ${pkgs.git}/bin/git -C "$TPM_DIR" pull --ff-only
      fi
    '';

    home.packages = with pkgs; [
      tmux
    ];

    home.shellAliases = {
      tx = "tmux";
    };
  };
}
