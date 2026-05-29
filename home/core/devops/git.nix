{
  pkgs,
  lib,
  userMeta,
  editorMeta,
  ...
}: let
  mail = userMeta.mail;
in {
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing.format = null;

    ignores = [
      "*~"
      ".DS_Store"
      "*.log"
      ".gitkeep"
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
        # 选中历史 commit → --fixup → 自动 autosquash rebase，全程零交互（EDITOR=true 跳过编辑器）
        # fixup = ''!f() { TARGET=$(git rev-parse "$1"); git commit --fixup=$TARGET ''${@:2} && EDITOR=true git rebase -i --autostash --autosquash $TARGET^; }; f'';

        # 提交中断后直接用上次的 message 重来（复用 .git/COMMIT_EDITMSG）
        # commit-reuse-message = ''!git commit --edit --file "$(git rev-parse --git-dir)"/COMMIT_EDITMSG'';
      };
      user = {
        name = "xbpk3t";
        email = mail;
      };

      core = {
        autocrlf = "input";
        filemode = false;
        editor = editorMeta.command;
      };
      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = true;
      };

      push = {
        default = "simple";
        # 新分支首次 push 自动设置 upstream，不用手动 -u
        autoSetupRemote = true;
      };
      # rebase 前自动 stash 未提交修改，rebase 后自动 pop
      rebase.autostash = true;
      credential.helper = "cache --timeout=7200";
      merge.conflictStyle = "diff3";
      # 自动记录并重放合并冲突解决模式，减少重复处理同类冲突
      rerere.enabled = true;
      # git branch 默认按最近提交时间降序排列，非字母序
      branch.sort = "-committerdate";

      log = {
        decorate = "full";
        date = "iso";
      };
    };
  };

  home.packages = with pkgs;
    [
      # 分类1：Git 核心操作与协作流程
      # tags(desc): 核心工具链 > 版本控制 > Git
      git
      # Git worktree 管理工具（AI 并行分支工作流很好用）
      # tags(desc): 分支工作流 > worktree管理 > 并行开发
      worktrunk

      # https://mynixos.com/nixpkgs/package/gitMinimal
      # [2025-12-11] 会跟git冲突，所以注释掉
      # gitMinimal # 确保 Git 在构建环境中可用

      # tags(desc): 大文件支持 > 版本控制 > Git生态
      git-lfs

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
      # tags(desc): 变更回滚 > 交互CLI > Git操作
      ugit

      # gitlab-cli
      # https://mynixos.com/nixpkgs/package/glab
      # https://gitlab.com/gitlab-org/cli
      # https://docs.gitlab.com/cli/
      # tags(desc): 平台集成 > GitLab > 代码托管
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
      # tags(desc): 工作流增强 > 子命令扩展 > Git生态
      (lib.lowPrio git-extras)
    ]
    ++ [
      # 分类2：代码质量、安全与历史清理
      # https://mynixos.com/nixpkgs/package/gitlint
      # tags(desc): 代码质量 > Commit规范 > Lint
      gitlint

      # tags(desc): 安全扫描 > 密钥泄漏 > 仓库安全
      gitleaks
    ]
    ++ [
      # 分类3：分析与可视化
      # https://github.com/git-quick-stats/git-quick-stats
      # tags(desc): 统计分析 > 仓库指标 > Git历史
      git-quick-stats
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
  # [2026-04-22] worktrunk 要比 agent-worktree 更好用。“对大多数人来说，worktrunk 更强、更全，也通常更值得优先选；但不能简单说 agent-worktree 的所有核心体验都被一比一包含了，它在‘单次 agent 闭环’和‘默认合回原 base’这两个点上是更明确的。”
  ## 要平台化、长期用、功能全：选 worktrunk。
  ## 要极简 agent 闭环、做完就收：agent-worktree 反而更“顺手”。
  xdg.configFile."worktrunk/config.toml".text = builtins.readFile ./worktrunk.toml;
  home.shellAliases = {
    # why: 修改为 PR-first，所以添加本alias来简化操作
    # what: 本来拼接 git status --short && wt step commit && git push -u origin HEAD && gh pr create --fill 这几条命令就行了，为啥要做一个 changes状态检查？
    # 在做该操作时会遇到几个corner case: 1、最核心的就是“检查是否有 untracked 文件”，否则。2、当前是否在worktree（还是main? 3、gh pr create相关的，不确定是否重复创建PR以及PR状态不清晰）。这个alias就解决了前两个核心问题。第三个问题 gh pr create本身就已经做处理了。
    # [2026-05-22] 移除 wt step commit：commit.stage = "none" 且 commit message 由 LLM 生成，与手动 commit 冲突
    wtpr = ''
      test -f "$(git rev-parse --show-toplevel 2>/dev/null)/.git" || {
        echo "Error: not a linked worktree"
        false
      } &&
      test -z "$(git status --porcelain)" || {
        echo "Error: working tree not clean"
        git status --short
        false
      } &&
      git push -u origin HEAD &&
      gh pr create --fill
    '';
    # 在用完 wtpr （PR merge）之后用来删除worktree（如果直接整合进去的话，可能会误删当前 worktree）
    wtc = "wt remove";
  };

  xdg.configFile."glab-cli/aliases.yml".text = ''
    ci: pipeline ci
    pr: mr
  '';
}
