{
  # [2025-10-12] MAYBE 目前zed相较goland的一些缺失功能
  # - [git side-by-side viewer] https://github.com/zed-industries/zed/discussions/26770
  # - [highlight] https://github.com/zed-industries/zed/issues/11895
  # https://github.com/zed-industries/zed/pull/9082
  # - [通过CMD+`切换项目] 怎么通过 CMD+` 快捷键，直接在多个project之间切换？我在配置 use_system_window_tabs 之前，本身通过 CMD+` 这种mac本身提供的窗口切换来切换项目是可行的，但是在添加该配置之后，因为本身没有多窗口了，所以怎么需要配置哪个快捷键来保证类似操作？
  # - [类似CMD+E切换最近修改文件]

  # 可供参考的zed配置
  # https://github.com/linkfrg/dotfiles/blob/main/modules/home-manager/software/zed/settings.nix
  # https://github.com/pabloagn/rhodium/blob/main/home/apps/ides/zed/default.nix
  # https://github.com/craole-cc/dotDots/blob/main/Admin/Packages/home/zed/settings.nix

  "icon_theme" = "Zed (Default)";

  # 默认使用JB的键位
  "base_keymap" = "JetBrains";

  # 直接使用stylix的theme
  # "ui_font_size" = 16;
  # "buffer_font_size" = 13;
  "tab_size" = 2;
  "preferred_line_length" = 120;
  # 换行，按照editor编辑区的可用width自动调整
  "soft_wrap" = "editor_width";
  "buffer_font_family" = "JetBrainsMono Nerd Font Mono";

  # 禁用OTel
  "telemetry" = {
    "diagnostics" = false;
    "metrics" = false;
  };

  # "theme" = {
  # "mode" = "dark";
  # "light" = "One Light";
  # Monokai for zed
  # "dark" = "Zedokai";
  # };

  # zed的scrollbar太粗了，所以禁用
  "scrollbar" = {
    "show" = "never";
  };

  # 禁用连字符
  "buffer_font_features" = {
    "calt" = false;
  };

  "terminal" = {
    "alternate_scroll" = "off";
    "blinking" = "terminal_controlled";
    "copy_on_select" = false;
    "keep_selection_on_copy" = true;
    # terminal 默认右侧
    "dock" = "right";
    "default_width" = 640;
    "default_height" = 320;
    "detect_venv" = {
      "on" = {
        "directories" = [
          ".env"
          "env"
          ".venv"
          "venv"
        ];
        "activate_script" = "default";
      };
    };
    "env" = {};
    "font_family" = null;
    "font_features" = {
      "calt" = false;
    };
    "font_size" = 12;
    "line_height" = "comfortable";
    "minimum_contrast" = 45;
    "option_as_meta" = false;
    "button" = true;
    "shell" = "system";
    "toolbar" = {
      "breadcrumbs" = false;
    };
    "working_directory" = "current_project_directory";

    "scrollbar" = {
      # 同上，同样因为zed的scrollbar太粗了
      "show" = "never";
    };
  };

  # 禁用
  "toolbar" = {
    "breadcrumbs" = false;
    "quick_actions" = false;
    "selections_menu" = false;
    "agent_review" = false;
    "code_actions" = false;
  };
  "tab_bar" = {
    "show" = false;
    "show_nav_history_buttons" = false;
    "show_tab_bar_buttons" = false;
  };

  # 仅限mac有该配置
  # 支持多个项目在同一个window，但是相应的如果配置后，就无法使用CMD+`来通过切换window来切换项目了。所以需要增加相应的自定义shortcut
  "use_system_window_tabs" = true;

  "indent_guides" = {
    "enabled" = true;
    "line_width" = 1;
    "active_line_width" = 1;
    "coloring" = "fixed";
    "background_coloring" = "disabled";
  };

  "close_on_file_delete" = true;

  "project_panel" = {
    "button" = true;
    "default_width" = 240;
    "dock" = "left";
    "entry_spacing" = "standard";
    "file_icons" = true;
    "folder_icons" = true;
    "git_status" = true;
    "indent_size" = 20;
    "auto_reveal_entries" = false;
    "auto_fold_dirs" = true;
    "drag_and_drop" = true;
    "scrollbar" = {
      "show" = "never";
    };
    "sticky_scroll" = true;
    "show_diagnostics" = "all";
    "indent_guides" = {
      "show" = "always";
    };
    "hide_root" = false;
    "starts_open" = true;
  };
  "collaboration_panel" = {
    "button" = false;
  };
  "outline_panel" = {
    "button" = true;
    "default_width" = 300;
    "dock" = "right";
    "file_icons" = true;
    "folder_icons" = true;
    "git_status" = true;
    "indent_size" = 20;
    "auto_reveal_entries" = true;
    "auto_fold_dirs" = true;
    "indent_guides" = {
      "show" = "always";
    };
    "scrollbar" = {
      "show" = null;
    };
  };
  "restore_on_startup" = "last_session";
  # AI Configuration - Enable Claude Code via ACP
  # Reference: https://zed.dev/blog/claude-code-via-acp
  "disable_ai" = false;
  "cursor_shape" = "bar";

  # Agent Configuration - Claude Code via ACP
  # Make sure you have the latest version of Zed
  # Find available agents in the Plus menu in the Agent Panel
  "agent" = {
    "provider" = "claude-code";
    # Claude Code will run as an independent process via ACP
    # Zed provides the UI for following edits, reviewing changes, and managing tasks
  };
  "gutter" = {
    "line_numbers" = true;
    "runnables" = true;
    "breakpoints" = true;
    "folds" = true;
    "min_line_number_digits" = 0;
  };
  "git" = {
    "git_gutter" = "hide";
    "inline_blame" = {
      "enabled" = false;
    };
    "branch_picker" = {
      "show_author_name" = true;
    };
    "hunk_style" = "staged_hollow";
  };

  # AI Features Configuration
  features = {
    # Enable AI features for Claude Code integration
    copilot = false; # Keep GitHub Copilot disabled, using Claude Code instead
    # Enable inline completion via AI
    # 默认
    # inline_completion_provider = "supermaven"; # or "none" if you prefer manual AI invocation
  };
  hour_format = "hour24";

  # https://linux.do/t/topic/929471
  language_models = {
    "openai_compatible" = {
      "glm-open" = {
        "api_url" = "https=//open.bigmodel.cn/api/paas/v4/";
        "available_models" = [
          {
            "name" = "glm-4.6";
            "display_name" = null;
            "max_tokens" = 128000;
            "max_output_tokens" = 80000;
            "max_completion_tokens" = 200000;
            "capabilities" = {
              "tools" = true;
              "images" = false;
              "parallel_tool_calls" = true;
              "prompt_cache_key" = true;
            };
          }
        ];
      };
    };
  };
}
