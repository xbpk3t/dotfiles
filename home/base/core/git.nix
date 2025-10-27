{
  myvars,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    git-lfs
    git-quick-stats # https://github.com/git-quick-stats/git-quick-stats
    gitleaks
    gitlint
    bfg-repo-cleaner # Git 大文件清理工具
    ugit
    git-who # https://github.com/sinclairtarget/git-who 一个开源的命令行工具，显示 Git 仓库的提交者统计。

    # Automatically trims your branches whose tracking remote refs are merged or gone
    # It's really useful when you work on a project for a long time.
    git-trim # 自动清理 Git 分支
  ];

  programs.git = {
    enable = true;
    userName = "xbpk3t";
    userEmail = myvars.mail;
    lfs.enable = true;

    # 全局忽略文件配置
    ignores = [
      # files
      "*~"
      ".DS_Store"
      "*.log"
      ".gitkeep"
      # dir
      ".idea"
    ];

    extraConfig = {
      core = {
        autocrlf = "input";
        filemode = false;
        editor = "nvim";
      };
      init = {
        defaultBranch = "main";
      };
      alias = {
      };
      # 凭证配置由 programs.gh 自动管理，无需手动配置
      # credential = {
      #   "https://github.com" = {
      #     helper = "!/usr/local/bin/gh auth git-credential";
      #   };
      #   "https://gist.github.com" = {
      #     helper = "!/usr/local/bin/gh auth git-credential";
      #   };
      # };

      # [2025-10-11] 配置singbox之后，默认使用TUN模式，不需要配置proxy
      #  http = {
      #    proxy = "http://127.0.0.1:7890";
      #  };
      #  https = {
      #    proxy = "http://127.0.0.1:7890";
      #  };
      pull = {
        rebase = true;
      };

      # FOSS-friendly settings
      push.default = "simple"; # Match modern push behavior
      credential.helper = "cache --timeout=7200";
      # Conflict resolution style for readable diffs
      merge.conflictStyle = "diff3";

      log = {
        decorate = "full"; # Show branch/tag info in git log
        date = "iso"; # ISO 8601 date format
      };
    };

    diff-so-fancy = {
      enable = true;
    };

    aliases = {
      br = "branch --sort=-committerdate";
      co = "checkout";
      df = "diff";
      com = "commit -a";
      gs = "stash";
      gp = "pull";
      lg = "log --graph --pretty=format:'%Cred%h%Creset - %C(yellow)%d%Creset %s %C(green)(%cr)%C(bold blue) <%an>%Creset' --abbrev-commit";
      st = "status";
    };
  };
}
