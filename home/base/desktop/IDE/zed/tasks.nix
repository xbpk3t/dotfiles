[
  # https://github.com/zed-industries/extensions/issues/523#issuecomment-3325210094
  {
    "label" = "List TODO/FIXME"; # 任务名称（在 Zed 任务列表里显示）
    "command" = "rg"; # 实际执行的命令（ripgrep）
    "args" = [
      "--vimgrep" # 输出包含 行/列 的格式，便于跳转
      "--hyperlink-format=file://{path}:{line}:{column}" # 生成带行列的超链接
      "-e TODO:" # 仅匹配带冒号的 TODO:
      "-e FIXME:" # 仅匹配带冒号的 FIXME:
      "-e PLAN:" # 仅匹配带冒号的 PLAN:
      "-e MAYBE:" # 仅匹配带冒号的 MAYBE:
      "." # 搜索起点（当前工作区根目录）
    ];
    "cwd" = "\${ZED_WORKTREE_ROOT}"; # 在当前工作区根目录执行
    "use_new_terminal" = true; # 在新终端运行，避免占用已有终端
    "allow_concurrent_runs" = false; # 禁止并发执行，避免结果交错
    "reveal" = "always"; # 总是展示任务输出面板
    "hide" = "never"; # 不自动隐藏任务输出
    "show_summary" = true; # 展示任务摘要
    "show_command" = true; # 展示实际运行的命令
    "reveal_target" = "center"; # 输出面板出现时居中
  }
  {
    "label" = "Scratch: New";
    "command" = "task";
    "args" = [
      "-g"
      "nb:new"
    ];
    "use_new_terminal" = true;
    "allow_concurrent_runs" = false;
    "reveal" = "always";
    "hide" = "never";
    "show_summary" = true;
    "show_command" = true;
    "reveal_target" = "center";
  }
  {
    "label" = "Scratch: List";
    "command" = "task";
    "args" = [
      "-g"
      "nb:list"
    ];
    "use_new_terminal" = true;
    "allow_concurrent_runs" = false;
    "reveal" = "always";
    "hide" = "never";
    "show_summary" = true;
    "show_command" = true;
    "reveal_target" = "center";
  }
  {
    "label" = "Scratch: Search";
    "command" = "task";
    "args" = [
      "-g"
      "nb:search"
    ];
    "use_new_terminal" = true;
    "allow_concurrent_runs" = false;
    "reveal" = "always";
    "hide" = "never";
    "show_summary" = true;
    "show_command" = true;
    "reveal_target" = "center";
  }
  {
    "label" = "Scratch: Rename";
    "command" = "task";
    "args" = [
      "-g"
      "nb:rename"
    ];
    "use_new_terminal" = true;
    "allow_concurrent_runs" = false;
    "reveal" = "always";
    "hide" = "never";
    "show_summary" = true;
    "show_command" = true;
    "reveal_target" = "center";
  }
  {
    "label" = "Scratch: Delete";
    "command" = "task";
    "args" = [
      "-g"
      "nb:delete"
    ];
    "use_new_terminal" = true;
    "allow_concurrent_runs" = false;
    "reveal" = "always";
    "hide" = "never";
    "show_summary" = true;
    "show_command" = true;
    "reveal_target" = "center";
  }
]
