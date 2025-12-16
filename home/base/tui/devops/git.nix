{pkgs, ...}: {
  home.packages = with pkgs; [
    git

    # https://mynixos.com/nixpkgs/package/gitMinimal
    # [2025-12-11] 会跟git冲突，所以注释掉
    # gitMinimal # 确保 Git 在构建环境中可用

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

  programs.diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;
  };
}
