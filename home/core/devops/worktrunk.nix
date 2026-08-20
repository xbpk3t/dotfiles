{ pkgs }:
let
  tomlFormat = pkgs.formats.toml { };
in
{

  home.packages = with pkgs; [
    # Git worktree 管理工具（AI 并行分支工作流很好用）
    # tags(desc): 分支工作流 > worktree管理 > 并行开发
    worktrunk
  ];

  # Worktrunk config（原散装 worktrunk.toml，已 Nix 化；注释不会带入生成的 toml，见 readme 语义）
  # CHANGELOG: 2026-05-21 切换 PR-first（commit.stage tracked→none，merge.commit true→false）
  xdg.configFile."worktrunk/config.toml".source = tomlFormat.generate "worktrunk-config.toml" {
    # Worktree 存放到 repo 内部，避免散落到同级目录
    # 注意：{{ branch | sanitize }} 会把 "/" 转成 "-"，防止路径非法
    worktree-path = "{{ repo_path }}/.worktrees/{{ branch | sanitize }}";

    # [post-create] → [post-start]：新版 hook 体系 post-create 已废弃；post-start 后台运行，失败不阻塞 wt switch
    post-start = {
      # 创建新 worktree 后在后台复制 ignored 文件；失败不会阻塞 wt switch
      copy = "wt step copy-ignored";
    };

    step = {
      copy-ignored = {
        # 避免复制临时图片、缓存、构建产物等不稳定/易缺失的文件
        exclude = [
          "docs-images/.temp/"
          ".cache/"
          ".turbo/"
          ".next/"
          "dist/"
          "build/"
        ];
      };
    };

    commit = {
      # all默认：git add -A（所有变化，包括 untracked）
      # tracked只 stage 已跟踪文件的修改（git add -u）
      # none不 staging，只提交当前已 staged 的内容
      stage = "none";

      # wt生成commit msg有两种方式（判断当前是否有 changes）：
      # 1、如果有未commit的changes，自动执行；command 有问题会产生 null commit msg
      # 2、如果changes区是干净的（手动commit了），不触发这个hook
      generation = {
        # LLM commit message 生成（Claude CLI 纯 API 模式）
        # CLAUDECODE=          关闭 Claude Code 扩展，纯 API 调用
        # MAX_THINKING_TOKENS=0  禁用 extended thinking
        # -p                    print 模式：从 stdin 读 prompt，输出到 stdout
        # --no-session-persistence  不保存会话历史
        # --model               AxonHub 代理上实际存在的模型（deepseek-v4-flash 更快更省）
        # --tools ''            禁用所有工具（无需文件访问）
        # --disable-slash-commands  禁用 skills/slash commands
        # --setting-sources ''  不加载任何 settings 文件，避免侧信道干扰
        # --system-prompt ''    清空系统提示词，完全由 Worktrunk 的 prompt 模板驱动
        command = "CLAUDECODE= MAX_THINKING_TOKENS=0 claude -p --no-session-persistence --model deepseek-v4-flash --tools '' --disable-slash-commands --setting-sources '' --system-prompt ''";
      };
    };

    list = {
      # true: 在 `wt list` 中显示 summary（会触发 commit.generation）
      # [2026-05-21] 改为false, 避免调用LLM，浪费token
      summary = false;
    };

    merge = {
      # 推荐默认安全合并策略：先 rebase、合并后自动 remove worktree、执行 hooks

      # 把当前 worktree 分支上 从 main 分出来之后的所有 commit，全部 squash（压扁）成一条新 commit
      # [2026-04-16] 修改为false，因为我需要在merge后，仍然保留worktree上的commit，而非合并为一个commit
      squash = false;
      commit = false;

      # 设置为true，否则会在merge时，会产生一个 Merge Commit
      rebase = true;
      remove = true;
      verify = true;

      # 默认为 true；rebase 后本身就是 fast-forward，显式声明避免歧义
      ff = true;
    };

    remove = {
      # 默认为 true；remove worktree 时同步删除对应分支
      delete-branch = true;
    };

    switch = {
      # 默认为 true；wt switch 后自动 cd 到新 worktree 目录
      cd = true;
    };
  };

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

}
