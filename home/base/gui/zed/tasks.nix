[
  {
    "label" = "List TODO/FIXME";
    "command" = "rg";
    "args" = [
      "--hyperlink-format=file://{path}"
      "-e TODO"
      "-e FIXME"
      "-e PLAN"
      "-e MAYBE"
      "."
    ];
    "cwd" = "${ZED_WORKTREE_ROOT}";
    "use_new_terminal" = true;
    "allow_concurrent_runs" = false;
    "reveal" = "always";
    "hide" = "never";
    "show_summary" = true;
    "show_command" = true;
    "reveal_target" = "center";
  }
]
