{
  pkgs,
  config,
  lib,
  userMeta,
  editorMeta,
  ...
}: let
  cfg = config.modules.devops.jj;
  mail = userMeta.mail;

  diff-formatter = [
    (pkgs.lib.getExe pkgs.difftastic)
    "--color=always"
    "$left"
    "$right"
  ];
in {
  options.modules.devops.jj = with lib; {
    enable = mkEnableOption "Enable jujutsu";
  };

  config = lib.mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;

      settings = {
        # 身份配置：name + email 用于 commit/amend 的作者信息
        user = {
          name = "xbpk3t";
          email = mail;
        };

        # SSH signing：仅签署自己的 commit（behaviour = "own"），不签署他人变更
        # backend = "ssh" 匹配 GitHub 的 SSH signing 验证方式
        signing = {
          behaviour = "own";
          backend = "ssh";
          key = "~/.ssh/id_ed25519.pub";
        };

        revsets.log = "default()";

        # revset-aliases: 自定义的 revision 选择器，简化常用查询
        revset-aliases = {
          # "main" branch 的 origin 跟踪（避免硬编码分支名）
          "trunk()" = "main@origin";
          # 未 push 的本地变更（用于 l alias）
          "compared_to_trunk()" = "(trunk()..@):: | (trunk()..@)-";
          # 不可变基点：内置 immutable + 所有远端 bookmark（避免误 rebase 已推送的 commit）
          "immutable_heads()" = "builtin_immutable_heads() | remote_bookmarks()";
          # 离指定 revision 最近的上游 bookmark（用于 tug alias）
          "closest_bookmark(to)" = "heads(::to & bookmarks())";
          # default log：当前 change + trunk 祖先 + recent visible heads
          "default_log()" = "present(@) | ancestors(immutable_heads().., 2) | present(trunk())";
          # all-revisions default：trunk 到当前的所有变更 + recent visible heads
          "default()" = "coalesce(trunk(),root())::present(@) | ancestors(visible_heads() & recent(), 2)";
          # 最近 1 周的变更
          "recent()" = "committer_date(after:'1 week ago')";
        };

        # template-aliases: 自定义 commit/change ID 展示格式
        template-aliases = {
          # change ID 短格式并转大写（默认小写，大写更易读）
          "format_short_id(id)" = "id.shortest().upper()";
          "format_short_change_id(id)" = "format_short_id(id)";
          # 作者显示 email 而非 name（多机器协同时可快速区分来源）
          "format_short_signature(signature)" = "signature.email()";
          # 时间戳显示相对时间（"2 hours ago"）
          "format_timestamp(timestamp)" = "timestamp.ago()";
        };

        # difftastic 作为默认 diff/show formatter：结构化 diff（按语法树对比而非行对比），
        # 支持 50+ 语言，对重构/格式化变更的 diff 可读性远优于传统行 diff
        "--scope" = [
          {
            "--when".commands = [
              "diff"
              "show"
            ];
            ui.diff-formatter = diff-formatter;
          }
        ];

        ui = {
          default-command = [
            "log"
            "--no-pager"
            "--reversed"
            "--stat"
            "--limit"
            "3"
          ];
          inherit diff-formatter;
          editor = editorMeta.command;
          diff-editor = "meld-3";
          merge-editor = "meld";
          conflict-marker-style = "git";
          movement.edit = false;
        };

        # 自定义 alias：简化日常 jj 操作
        aliases = {
          # sq: interactive squash（选择当前 change 往哪合并）
          sq = [
            "squash"
            "-i"
          ];
          # su: squash @ 往上（@ 的内容合并到 @+）
          su = [
            "squash"
            "-i"
            "-f"
            "@"
            "-t"
            "@+"
          ];
          # sd: squash @ 往下（@ 的内容合并到 @-）
          sd = [
            "squash"
            "-i"
            "-f"
            "@"
            "-t"
            "@-"
          ];
          # sU: squash 上方的 change 到 @（@+ 合并到 @）
          sU = [
            "squash"
            "-i"
            "-f"
            "@+"
            "-t"
            "@"
          ];
          # sD: squash 下方的 change 到 @（@- 合并到 @）
          sD = [
            "squash"
            "-i"
            "-f"
            "@-"
            "-t"
            "@"
          ];

          # s: show 当前 change 的 diff
          s = ["show"];

          # l: log 未 push 的本地变更（compared_to_trunk）
          l = [
            "log"
            "-r"
            "compared_to_trunk()"
          ];

          # ll: log 所有 change（不分隔）
          ll = [
            "log"
            "-r"
            ".."
          ];

          # lr: log 最近 1 周的变更
          lr = [
            "log"
            "-r"
            "default() & recent()"
          ];

          # tug: 将当前 branch bookmark 移到父 change（用于 bookmark 跟随后移）
          tug = [
            "bookmark"
            "move"
            "--from"
            "closest_bookmark(@-)"
            "--to"
            "@-"
          ];
        };
      };
    };

    # difftastic: 语法树 diff（jj 的 diff-formatter 依赖）；lazyjj: TUI 浏览器；jj-fzf: fzf 集成
    home.packages = [
      pkgs.difftastic
      pkgs.lazyjj
      pkgs.jj-fzf
      pkgs.jj-starship
    ];
  };
}
