[
  {
    context = "Workspace";
    bindings = {
      ctrl-shift-t = "workspace==NewTerminal";
    };
  }
  {
    context = "Workspace";
    bindings = {
      "cmd-shift-t" = "pane==ReopenClosedItem";
    };
  }
  {
    context = "(Workspace || Editor)";
    bindings = {
      "cmd-shift-t" = "terminal_panel==Toggle";
    };
  }
  {
    context = "Pane";
    bindings = {
      "cmd-k" = "git_panel==ToggleFocus";
    };
  }
  {
    bindings = {
      "cmd-k" = "git_panel==ToggleFocus";
    };
  }
]
