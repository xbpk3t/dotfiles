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
