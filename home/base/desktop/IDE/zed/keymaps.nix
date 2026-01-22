[
  # {
  # context = "Editor";
  # bindings = {
  # 类似IDEA生态下知名的 StringManipulation 插件（字符串大小写切换）。zed本身内置了
  ## 驼峰式（Camel Case）、蛇形（Snake Case）、烤肉串（Kebab Case）、帕斯卡（Pascal Case）、大驼峰（Upper Camel Case）
  ## 小驼峰（lowerCamelCase） 大驼峰（UpperCamelCase / Pascal Case） 小蛇形（lower_snake_case）烤肉串命名法（Kebab Case）user-name, get-user-info, css-class-name
  #
  # 在设置为，本身已经可以通过 CMD+Shift+U 做 Toggle Case 操作，所以就不需要配置以下这些操作了。需要时，直接通过 Pannel 调用即可。
  #
  # cmd-alt-c = "editor::ConvertToLowerCamelCase";
  # cmd-alt-shift-c = "editor::ConvertToUpperCamelCase";
  # };
  # }

  #  {
  #    context = "Workspace";
  #    bindings = {
  #      ctrl-shift-t = "workspace==NewTerminal";
  #    };
  #  }
  #  {
  #    context = "Workspace";
  #    bindings = {
  #      "cmd-shift-t" = "pane==ReopenClosedItem";
  #    };
  #  }
  #  {
  #    context = "(Workspace || Editor)";
  #    bindings = {
  #      "cmd-shift-t" = "terminal_panel==Toggle";
  #    };
  #  }
  #  {
  #    context = "Pane";
  #    bindings = {
  #      "cmd-k" = "git_panel==ToggleFocus";
  #    };
  #  }
  #  {
  #    bindings = {
  #      "cmd-k" = "git_panel==ToggleFocus";
  #    };
  #  }
  #

  # https://github.com/jellydn/zed-101-setup#keymaps

  {
    context = "Editor && (vim_mode == normal || vim_mode == visual) && !VimWaiting && !menu";
    bindings = {
      "space g h d" = "editor::ToggleSelectedDiffHunks";
      "space g s" = "git_panel::ToggleFocus";
      "space t i" = "editor::ToggleInlayHints";
      "space u w" = "editor::ToggleSoftWrap";
      "space c z" = "workspace::ToggleCenteredLayout";
      "space m p" = "markdown::OpenPreview";
      "space m P" = "markdown::OpenPreviewToTheSide";
      "space f p" = "projects::OpenRecent";
      "space s w" = "pane::DeploySearch";
      "space a c" = "assistant::ToggleFocus";
      "g f" = "editor::OpenExcerpts";
    };
  }
  {
    context = "Editor && vim_mode == normal && !VimWaiting && !menu";
    bindings = {
      ctrl-h = "workspace::ActivatePaneLeft";
      ctrl-l = "workspace::ActivatePaneRight";
      ctrl-k = "workspace::ActivatePaneUp";
      ctrl-j = "workspace::ActivatePaneDown";
      "space c a" = "editor::ToggleCodeActions";
      "space ." = "editor::ToggleCodeActions";
      "space c r" = "editor::Rename";
      "g d" = "editor::GoToDefinition";
      "g D" = "editor::GoToDefinitionSplit";
      "g i" = "editor::GoToImplementation";
      "g I" = "editor::GoToImplementationSplit";
      "g t" = "editor::GoToTypeDefinition";
      "g T" = "editor::GoToTypeDefinitionSplit";
      "g r" = "editor::FindAllReferences";
      "] d" = "editor::GoToDiagnostic";
      "[ d" = "editor::GoToPreviousDiagnostic";
      "] e" = "editor::GoToDiagnostic";
      "[ e" = "editor::GoToPreviousDiagnostic";
      "s s" = "outline::Toggle";
      "s S" = "project_symbols::Toggle";
      "space x x" = "diagnostics::Deploy";
      "] h" = "editor::GoToHunk";
      "[ h" = "editor::GoToPreviousHunk";
      shift-h = "pane::ActivatePreviousItem";
      shift-l = "pane::ActivateNextItem";
      shift-q = "pane::CloseActiveItem";
      ctrl-q = "pane::CloseActiveItem";
      "space b d" = "pane::CloseActiveItem";
      "space b o" = "pane::CloseInactiveItems";
      ctrl-s = "workspace::Save";
      "space space" = "file_finder::Toggle";
      "space /" = "pane::DeploySearch";
      "space e" = "pane::RevealInProjectPanel";
    };
  }
  {
    context = "EmptyPane || SharedScreen";
    bindings = {
      "space space" = "file_finder::Toggle";
      "space f p" = "projects::OpenRecent";
    };
  }

  # [2026-01-22] 以下这部分配置会又些影响日常使用，比如说输入j开头的中文，会触发以下操作
  #
  #
  # {
  #   context = "Editor && vim_mode == visual && !VimWaiting && !menu";
  #   bindings = {
  #     "g c" = "editor::ToggleComments";
  #   };
  # }
  # {
  #   context = "Editor && vim_mode == insert && !menu";
  #   bindings = {
  #     "j j" = "vim::NormalBefore";
  #     "j k" = "vim::NormalBefore";
  #   };
  # }
  # {
  #   context = "Editor && vim_operator == c";
  #   bindings = {
  #     c = "vim::CurrentLine";
  #     r = "editor::Rename";
  #   };
  # }
  # {
  #   context = "Editor && vim_operator == c";
  #   bindings = {
  #     c = "vim::CurrentLine";
  #     a = "editor::ToggleCodeActions";
  #   };
  # }
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
      "space e" = "workspace::ToggleRightDock";
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
  {
    context = "EmptyPane || SharedScreen || vim_mode == normal";
    bindings = {
      "space r t" = [
        "editor::SpawnNearestTask"
        {
          reveal = "no_focus";
        }
      ];
    };
  }
  {
    context = "vim_mode == normal || vim_mode == visual";
    bindings = {
      s = [
        "vim::PushSneak"
        {
        }
      ];
      S = [
        "vim::PushSneakBackward"
        {
        }
      ];
    };
  }
]
