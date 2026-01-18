[
  {
    context = "Editor";
    bindings = {
      # 类似IDEA生态下知名的 StringManipulation 插件（字符串大小写切换）。zed本身内置了
      ## 驼峰式（Camel Case）、蛇形（Snake Case）、烤肉串（Kebab Case）、帕斯卡（Pascal Case）、大驼峰（Upper Camel Case）
      ## 小驼峰（lowerCamelCase） 大驼峰（UpperCamelCase / Pascal Case） 小蛇形（lower_snake_case）烤肉串命名法（Kebab Case）user-name, get-user-info, css-class-name
      #
      # 在设置为，本身已经可以通过 CMD+Shift+U 做 Toggle Case 操作，所以就不需要配置以下这些操作了。需要时，直接通过 Pannel 调用即可。
      #
      # cmd-alt-c = "editor::ConvertToLowerCamelCase";
      # cmd-alt-shift-c = "editor::ConvertToUpperCamelCase";
    };
  }

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
]
