{
  pkgs,
  editorMeta,
  ...
}:
{
  home.packages = with pkgs; [
    lazygit
    # 新增 delta 以支持 side-by-side diff
    # lazygit 对 delta 依赖
    delta
  ];

  # https://mynixos.com/home-manager/options/programs.gitui
  # [2026-05-22] 再次对比 lazygit和 gitui，其实后者更好用，但是目前后者不支持
  # programs.gitui = {
  #   enable = true;
  #   #  keyConfig = ''
  #   #      page_up: Some(( code: Char('j'), modifiers: "")),
  #   #      page_own: Some(( code: Char('k'), modifiers: "")),
  #   #      diff_hunk_prev: Some(( code: Char('l'), modifiers: "")),
  #   #      diff_hunk_next: Some(( code: Char('h'), modifiers: "")),
  #   #      commit: Some((code: Char('y'), modifiers: "CONTROL")),
  #   #      exit: Some((code: Char('n'), modifiers: "CONTROL")),
  #   #      open_help: Some((code: Char('?'), modifiers: ""))
  #   #  '';

  #   # [catppuccin/gitui: 🍴 Soothing pastel theme for GitUI](https://github.com/catppuccin/gitui)
  #   #  theme = ''
  #   #        selected_tab: Some("Reset"),
  #   #        command_fg: Some("#c6d0f5"),
  #   #        selection_bg: Some("#626880"),
  #   #        selection_fg: Some("#c6d0f5"),
  #   #        cmdbar_bg: Some("#292c3c"),
  #   #        cmdbar_extra_lines_bg: Some("#292c3c"),
  #   #        disabled_fg: Some("#838ba7"),
  #   #        diff_line_add: Some("#a6d189"),
  #   #        diff_line_delete: Some("#e78284"),
  #   #        diff_file_added: Some("#a6d189"),
  #   #        diff_file_removed: Some("#ea999c"),
  #   #        diff_file_moved: Some("#ca9ee6"),
  #   #        diff_file_modified: Some("#ef9f76"),
  #   #        commit_hash: Some("#babbf1"),
  #   #        commit_time: Some("#b5bfe2"),
  #   #        commit_author: Some("#85c1dc"),
  #   #        danger_fg: Some("#e78284"),
  #   #        push_gauge_bg: Some("#8caaee"),
  #   #        push_gauge_fg: Some("#303446"),
  #   #        tag_fg: Some("#f2d5cf"),
  #   #        branch_fg: Some("#81c8be")
  #   #  '';
  # };

  programs.lazygit = {
    enable = true;
    package = pkgs.lazygit;
    settings = {
      git = {
        pagers = [
          {
            colorArg = "always";

            # side-by-side viewer
            # --paging=never 是必需的，确保 delta 不自行分页（lazygit 会处理）
            # 注意这里使用 catppuccin theme，因为 stylix 生成的不太好看
            pager = "delta -s --paging=never --line-numbers --dark";
          }
        ];
        disableForcePushing = true;
      };
      gui = {
        language = "en";
        mouseEvents = false;
        sidePanelWidth = 0.2;
        mainPanelSplitMode = "flexible"; # one of "horizontal" | "flexible" | "vertical"
        showFileTree = false; # ` to toggle
        nerdFontsVersion = "3";
        commitHashLength = 6;
        showDivergenceFromBaseBranch = "arrowAndNumber";
      };
      quitOnTopLevelReturn = true;
      disableStartupPopups = true;
      promptToReturnFromSubprocess = false;
      os = {
        editPreset = editorMeta.lazygitPreset;
      };
      keybinding = {
        files = {
          stashAllChanges = "<c-a>"; # instead of just 's' which I typod for 'c'
        };
        universal = {
          prevItem = "e";
          nextItem = "n";
          scrollUpMain = "<up>"; # main panel scroll up
          scrollDownMain = "<down>"; # main panel scroll down
          nextMatch = "j";
          prevMatch = "J";
          new = "<c-a>";
          edit = "<c-r>";
        };
      };
      # https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_Command_Keybindings.md
      customCommands = [
        {
          key = "H";
          context = "commits";
          # or use "y u" to copy the url
          command = "gh browse {{.SelectedLocalCommit.Hash}}";
        }
        # 新增：绑定 wt step commit 到 files 面板
        {
          key = "C"; # 选用大写 C 避免与原生快捷键冲突
          context = "files";
          command = "wt step commit";
          output = "terminal"; # 必须为 terminal 以便进入 wt 的交互式命令行
          loadingText = "Launching wt commit wizard...";
          description = "Run wt step commit for staged changes";
        }
      ];
    };
  };
}
