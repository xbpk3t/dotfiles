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
  xdg.configFile."worktrunk/config.toml".text = ''
    # Worktree 存放到 repo 内部，避免散落到同级目录
    # 注意：{{ branch | sanitize }} 会把 "/" 转成 "-"，防止路径非法
    worktree-path = "{{ repo_path }}/.worktrees/{{ branch | sanitize }}"

    [post-create]
    # 每次创建新 worktree 后执行自定义 step
    # 注意：依赖你本地已定义 `wt step copy-ignored`
    copy = "wt step copy-ignored"

    [commit]
    # stage = "all" 会在 merge/squash 流程里自动 add 所有改动
    # 如果你希望更保守，可改为 "tracked" 或 "none"
    stage = "all"

    [commit.generation]
    # LLM commit message 生成命令（使用 Codex CLI）
    # 关键点：必须从 stdin 读取 prompt（结尾 `-`），否则 wt 传入内容不会生效
    # 关键点：`--json | jq` 只提取最终 agent_message，避免事件流污染 commit message
    # 关键点：`--sandbox read-only` 只生成文本，不执行写操作，更安全
    command = "codex exec --json --sandbox read-only --skip-git-repo-check -m gpt-5.4-mini -c model_reasoning_effort='low' - | jq -sr '[.[] | select(.type == \"item.completed\" and .item.type == \"agent_message\")] | last.item.text'"

    [list]
    # 在 `wt list` 中显示 summary（会触发 commit.generation）
    summary = true

    [merge]
    # 推荐默认安全合并策略：先 rebase、合并后自动 remove worktree、执行 hooks
    squash = true
    commit = true
    rebase = true
    remove = true
    verify = true
  '';
}
