{
  pkgs,
  lib,
  userMeta,
  editorMeta,
  ...
}:
let
  inherit (userMeta) mail;
in
{
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
        # 是否忽略文件名大小写（linux默认区分，windows/macos默认不区分（也就是为true），所以需要显式声明false）
        ignorecase = false;
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

  home.packages =
    with pkgs;
    [
      # 分类1：Git 核心操作与协作流程
      # tags(desc): 核心工具链 > 版本控制 > Git
      git
      # Git worktree 管理工具（AI 并行分支工作流很好用）
      # tags(desc): 分支工作流 > worktree管理 > 并行开发
      worktrunk

      # tags(desc): 大文件支持 > 版本控制 > Git生态
      git-lfs

      ugit

      glab
      (lib.lowPrio git-extras)
      git-filter-repo

      commitizen
    ]
    ++ [
      # 分类2：代码质量、安全与历史清理

      # tags(desc): 安全扫描 > 密钥泄漏 > 仓库安全
      gitleaks
    ]
    ++ [
      # 分类3：分析与可视化
      # tags(desc): 统计分析 > 仓库指标 > Git历史
      git-quick-stats
    ];

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
