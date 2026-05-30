{
  editorMeta,
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.gh = {
    enable = true;

    settings = {
      # Git 协议设置
      git_protocol = "https";

      # 编辑器设置
      editor = editorMeta.command;

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

    # gh extensions are package values; Home Manager links them under gh/extensions.
    extensions = with pkgs; [
      # gh-stack: stacked PR workflow.
      # 用于把大改动拆成多层依赖 PR：底层 PR base=main，上层 PR base=前一层分支。
      # 适合 agent/人工把复杂任务切成可 review 的小 PR；不用时只是多一个 gh stack 子命令。
      gh-stack

      # gh-dash: terminal dashboard for PRs and issues.
      # 用来集中扫 assigned/review-requested PR、issue 和状态，比反复 gh pr list / 浏览器切页更高效。
      gh-dash

      # gh-f: fzf-powered GitHub picker.
      # 用模糊搜索选择 repo/issue/PR 等对象，减少手输编号和 URL，和现有 gh aliases 互补。
      gh-f

      # gh-poi: safely clean up local branches after PRs are merged or closed.
      # 适合多 repo/多分支工作流，降低本地分支堆积；比手写 git branch 清理脚本更稳。
      gh-poi
    ];
  };

  # 添加 gh 相关的 shell 别名
  programs.zsh.shellAliases = {
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

  home.sessionVariables = {
    # GitHub PAT is managed by sops and exported for gh, MCP servers, agents, and nix fetches.
    GITHUB_TOKEN = lib.mkForce "$(cat ${config.sops.secrets.GITHUB_TOKEN.path})";

    # For xbpk3t/docs rss2newsletter
    RESEND_TOKEN = "$(cat ${config.sops.secrets.RESEND_TOKEN.path})";
  };

  home.sessionVariablesExtra = lib.mkAfter ''
    # Keep GITHUB_TOKEN as the single secret source, then derive compatibility names
    # after hm-session-vars.sh has exported it. Putting these in home.sessionVariables
    # would be order-sensitive because Home Manager emits attrs alphabetically.
    if [ -n "$GITHUB_TOKEN" ]; then
      export GH_TOKEN="$GITHUB_TOKEN"
      export CODEX_GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
      export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
      export NIX_CONFIG="access-tokens = github.com=$GITHUB_TOKEN"
    fi
  '';
}
