_: {
  programs.git = {
    enable = true;
    userName = "XBPk3T";
    userEmail = "yyzw@live.com";
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
        la = "log --pretty=format:'%C(yellow)%h%Creset %C(green)(%cd)%Creset %C(bold blue)<%cn>%Creset%C(red)%d%Creset %C(white)%s%Creset' --date=format-local:'%Y-%m-%d %H:%M:%S' --graph --all";
      };
      credential = {
        "https://github.com" = {
          helper = "!/usr/local/bin/gh auth git-credential";
        };
        "https://gist.github.com" = {
          helper = "!/usr/local/bin/gh auth git-credential";
        };
      };
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
