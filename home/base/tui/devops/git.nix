{pkgs, ...}: {
  home.packages = with pkgs; [
    git
    # Git worktree 管理工具（AI 并行分支工作流很好用）
    worktrunk

    # https://mynixos.com/nixpkgs/package/gitMinimal
    # [2025-12-11] 会跟git冲突，所以注释掉
    # gitMinimal # 确保 Git 在构建环境中可用

    git-lfs
    # https://github.com/git-quick-stats/git-quick-stats
    git-quick-stats
    gitleaks

    # https://mynixos.com/nixpkgs/package/gitlint
    gitlint
    # Git 大文件清理工具
    bfg-repo-cleaner
    ugit
    # https://github.com/sinclairtarget/git-who 一个开源的命令行工具，显示 Git 仓库的提交者统计。
    git-who

    # 自动清理 Git 分支
    # Automatically trims your branches whose tracking remote refs are merged or gone
    # It's really useful when you work on a project for a long time.
    git-trim

    # 换到zed之后，不支持 git commit history，需要用TUI工具补充该feat
    #
    #
    # 终端提交拓扑图浏览器：把 commit graph 渲染得更清晰，主打看分支关系。
    #
    # https://mynixos.com/nixpkgs/package/serie
    # https://github.com/lusingander/serie
    serie
    #
    # 终端 Git 历史浏览器：看提交列表、选中即看 diff，可当 git pager。
    #
    # https://mynixos.com/nixpkgs/package/tig
    # https://github.com/jonas/tig
    tig
  ];

  programs.diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;
  };

  # worktrunk
  # hooks、AI 集成、缓存、merge
  # why this? 也有 WorktreeWise, git-wt, LazyWorktree 等其他类似工具，为啥选择这个？
  xdg.configFile."worktrunk/config.toml".text = builtins.readFile ./worktrunk.toml;
}
