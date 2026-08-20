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
  programs = {
    git = {
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
          # st = "status";
          # 选中历史 commit → --fixup → 自动 autosquash rebase，全程零交互（EDITOR=true 跳过编辑器）
          # fixup = ''!f() { TARGET=$(git rev-parse "$1"); git commit --fixup=$TARGET ''${@:2} && EDITOR=true git rebase -i --autostash --autosquash $TARGET^; }; f'';

          # 提交中断后直接用上次的 message 重来（复用 .git/COMMIT_EDITMSG）
          # commit-reuse-message = ''!git commit --edit --file "$(git rev-parse --git-dir)"/COMMIT_EDITMSG'';

          # 当前 worktree 相对 main 多的 commits(主要答案)
          # git log main..HEAD --oneline
          # # 要是想看反过来,main 比这个分支多的
          # git log HEAD..main --oneline
          # # 如果 main 分支的本地引用是旧的,用远端的最新状态更准
          # git log origin/main..HEAD --oneline
          wt-diff = "log main..HEAD --oneline";
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

    # worktrunk shell integration：让 `wt switch` 能在当前 shell 里 cd。
    # HM 管理的 ~/.zshrc 是只读 symlink，不能依赖 `wt config shell install`。
    # 与包 / config.toml / wtpr·wtc 同放本模块，避免散落在 kernel zsh-init。
    zsh.initContent = lib.mkAfter ''
      if command -v wt >/dev/null 2>&1; then
        eval "$(command wt config shell init zsh)"
      fi
    '';

  };

  home.packages =
    with pkgs;
    [
      # 分类1：Git 核心操作与协作流程
      # tags(desc): 核心工具链 > 版本控制 > Git
      git

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

  xdg.configFile."glab-cli/aliases.yml".text = ''
    ci: pipeline ci
    pr: mr
  '';
}
