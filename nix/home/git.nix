{
  mail,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    git-lfs
    git-quick-stats # https://github.com/git-quick-stats/git-quick-stats
    gitleaks
    gitlint
    bfg-repo-cleaner
    ugit
    git-who # https://github.com/sinclairtarget/git-who 一个开源的命令行工具，显示 Git 仓库的提交者统计。
  ];

  programs.git = {
    enable = true;
    userName = "XBPk3T";
    userEmail = mail;
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
      http = {
        proxy = "http://127.0.0.1:7890";
      };
      https = {
        proxy = "http://127.0.0.1:7890";
      };
      pull = {
        rebase = true;
      };
    };
  };
}
