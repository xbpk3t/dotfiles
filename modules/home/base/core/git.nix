{myvars, ...}: {
  programs.git = {
    enable = true;
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

    settings = {
      alias = {
        br = "branch --sort=-committerdate";
        co = "checkout";
        df = "diff";
        com = "commit -a";
        gs = "stash";
        gp = "pull";
        lg = "log --graph --pretty=format:'%Cred%h%Creset - %C(yellow)%d%Creset %s %C(green)(%cr)%C(bold blue) <%an>%Creset' --abbrev-commit";
        st = "status";
      };
      user = {
        name = "xbpk3t";
        email = myvars.mail;
      };

      core = {
        autocrlf = "input";
        filemode = false;
        editor = "nvim";
      };
      init = {
        defaultBranch = "main";
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
  };
}
