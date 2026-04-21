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

    # https://github.com/Bhupesh-V/ugit
    # 千呼万唤才出来的git工具，用来撤销git操作。最经典的场景就是，经常有那种已经commit了，然后还有点代码想放到那个commit里提交上去。这个就很难操作，这种情况下用ugit就很容易了。
    # 使用 ugit 撤销上一次 Git 操作（支持交互式选择）
    #- 操作场景: 【回滚本地未提交代码】丢弃未暂存更改
    #  原生 Git 命令: "git restore . 或 git checkout -- ."
    #  ugit 替代方案: "ugit → 选择 Undo git add"
    #
    #- 操作场景: 【回滚本地已提交的代码】
    #  原生 Git 命令: "git reset --soft HEAD~1（保留修改）；git reset --hard HEAD~1（彻底删除）"
    #  ugit 替代方案: "ugit → 选择 Undo git commit"
    #
    #- 操作场景: 回滚所有未暂存/未贮藏代码
    #  原生 Git 命令: "git restore . && git clean -df（含未跟踪文件）"
    #  ugit 替代方案: "ugit → 组合使用 Undo git add + git clean"
    #
    #- 操作场景: 【撤回已 push 的提交】
    #  原生 Git 命令: "git revert <commit>（安全）；git reset --hard <commit> && git push -f（危险）"
    #  ugit 替代方案: "ugit → 选择 Undo git push"
    #
    #- 操作场景: 恢复误删除的 commit
    #  原生 Git 命令: "git reflog → 找到 commit hash → git reset --hard <hash>"
    #  ugit 替代方案: "ugit → 选择 Undo git reset"
    #
    #- 操作场景: 彻底删除历史 commit
    #  原生 Git 命令: "git reset --hard <commit-id>（本地）；git push origin HEAD --force（远程）"
    #  ugit 替代方案: "ugit 仅支持删除最近 commit（等效 reset HEAD~1）"
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

    # gitlab-cli
    # https://mynixos.com/nixpkgs/package/glab
    # https://gitlab.com/gitlab-org/cli
    # https://docs.gitlab.com/cli/
    glab

    # https://github.com/tj/git-extras
    # https://mynixos.com/nixpkgs/package/git-extras
    # 注意 git-extras 直接使用git的插件扩展机制（Subcommand Expansion），所以直接以 git命令直接调用
    #analysis_&_stats:
    #  - command: git summary
    #    description: "查看仓库概况（提交次数、活跃时长、文件数等）"
    #  - command: git effort
    #    description: "显示每个文件的提交频率，识别代码热点"
    #  - command: git authors
    #    description: "列出所有贡献者及其贡献百分比"
    #  - command: git info
    #    description: "显示当前仓库的详细信息（远程、分支、配置）"
    #
    #workflow_&_release:
    #  - command: git changelog
    #    description: "自动从提交历史中提取并生成 CHANGELOG 文本"
    #  - command: git release
    #    description: "一键完成提交、打标（tag）、推送的全流程"
    #  - command: git feature
    #    description: "简单的功能分支管理流程（创建/合并/删除）"
    #  - command: git standup
    #    description: "显示你今天或最近几天的提交记录，用于站会汇报"
    #
    #cleanup_&_maintenance:
    #  - command: git delete-merged-branches
    #    score: 5
    #    description: "一键清理本地所有已经合并到主分支的废弃分支"
    #  - command: git delete-submodule
    #    description: "从项目中彻底移除子模块，无需手动修改 .gitmodules"
    #  - command: git squash
    #    score: 5
    #    description: "将多个提交合并为一个，保持提交历史整洁"
    #  - command: git clear
    #    description: "类似 git reset --hard，但更彻底且安全地重置工作区"
    #
    #utilities:
    #  - command: git sync
    #    description: "自动执行拉取、重基（rebase）并推送，保持双向同步"
    #  - command: git ignore [pattern]
    #    description: "快速将文件模式添加到 .gitignore 且不重复添加"
    #  - command: git sed
    #    description: "在整个项目文件的历史记录中进行字符串查找替换"
    #  - command: git browse
    #    description: "直接在浏览器中打开当前仓库的远程页面（GitHub/GitLab）"
    #  - command: git repl
    #    description: "进入一个专门的 Git 交互式 Shell 模式"

    # git sync upstream main
    # git obliterate {{.PATH}}
    ## 替换原来的 sync-upstream
    #  sync-upstream:
    #    desc: "使用 git-extras 同步上游代码"
    #    cmd: git sync upstream main
    #
    #  # 替换/增强搜索任务
    #  search-and-replace:
    #    desc: "全项目字符串替换 (谨慎使用)"
    #    summary: "task -g search-and-replace OLD=... NEW=..."
    #    cmd: git sed {{.OLD}} {{.NEW}}
    #
    #  # 定点抹除大文件/敏感文件
    #  obliterate:
    #    desc: "从历史中彻底删除指定路径 (git-extras)"
    #    cmd: git obliterate {{.PATH}}
    git-extras
  ];

  # https://mynixos.com/home-manager/options/services.git-sync
  # https://mynixos.com/nixpkgs/package/git-sync
  # https://github.com/simonthum/git-sync
  services.git-sync = {
    enable = true;
    #    repositories = {
    #        notes = {
    #          path = "/home/user/notes";
    #          uri = "git@github.com:username/notes.git";
    #          interval = 300; # 每5分钟同步一次
    #        };
    #      };
  };

  programs.diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;
  };

  # worktrunk
  # hooks、AI 集成、缓存、merge
  # why this? 也有 WorktreeWise, git-wt, LazyWorktree 等其他类似工具，为啥选择这个？
  # 这个要比 git-wt 好用
  # https://github.com/k1LoW/git-wt
  # https://mynixos.com/nixpkgs/package/git-wt
  xdg.configFile."worktrunk/config.toml".text = builtins.readFile ./worktrunk.toml;

  xdg.configFile."glab-cli/aliases.yml".text = ''
    ci: pipeline ci
    pr: mr
  '';
}
