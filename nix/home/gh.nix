{...}: {
  programs.gh = {
    enable = true;

    settings = {
      # Git 协议设置
      git_protocol = "https";

      # 编辑器设置
      editor = "nvim";

      # 提示设置
      prompt = "enabled";

      # 分页器设置
      pager = "less";

      # 别名配置
      aliases = {
        # 仓库相关
        co = "pr checkout";
        pv = "pr view";
        pc = "pr create";
        pm = "pr merge";

        # Issue 相关
        iv = "issue view";
        ic = "issue create";

        # 仓库管理
        rc = "repo clone";
        rv = "repo view";
        rf = "repo fork";

        # 工作流相关
        wv = "workflow view";
        wr = "workflow run";

        # 发布相关
        rv-release = "release view";
        rc-release = "release create";

        # 用户相关
        profile = "api user";

        # 快捷操作
        st = "status";
        sync = "repo sync";
      };
    };

    # 扩展配置
    extensions = [
      # "gh-dash"  # 如果你想使用 gh-dash 扩展
    ];

    # 环境变量
    # env = {
    #   GH_TOKEN = "your_token";  # 通常通过 gh auth login 设置
    # };
  };

  # 添加 gh 相关的 shell 别名
  programs.bash.shellAliases = {
    # GitHub 快捷操作
    #    ghpc = "gh pr create --web";
    #    ghpv = "gh pr view --web";
    #    ghiv = "gh issue view --web";
    #    ghic = "gh issue create --web";
    #    ghrv = "gh repo view --web";
    #
    #    # 快速克隆
    #    ghc = "gh repo clone";
    #    # 查看当前仓库状态
    #    ghs = "gh status";
  };
}
