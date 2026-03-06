{
  pkgs,
  mylib,
  ...
}: let
  # 保留 .taskfile 目录（子 Taskfile、脚本、assets），直接同步到 $HOME/taskfile/
  taskfileDir = mylib.relativeToRoot ".taskfile";

  # 生成供 `task -g` 使用的 Taskfile.yml
  # - 仅保留 version + includes，其他字段不需要进入全局入口
  # - 为 includes 的路径自动补齐前缀 taskfile/，并去掉开头的 ./ 或已有的 taskfile/，防止重复
  # - 当前仓库 includes 均为字符串路径；若后续引入 map 形式，需要再扩展表达式
  taskfileGlobal =
    pkgs.runCommand "taskfile-global.yml" {
      buildInputs = [pkgs.yq-go]; # mikefarah/yq (Go 版)
    } ''
      yq eval '. as $r | {"version": ($r.version // "3"),
        "includes": (
          ($r.includes // {}) | with_entries(
            .value = "taskfile/" + (
              .value
              | sub("^\\./","")
              | sub("^taskfile/","")
            )
          )
        )
      }' ${mylib.relativeToRoot ".taskfile/Taskfile.yml"} > $out
    '';
in {
  # 分发 .taskfile 目录（供 includes 解析到子 Taskfile）
  home.file."taskfile" = {
    source = taskfileDir;
    recursive = true;
    force = true;
  };

  # 分发由 Nix 生成的全局入口 Taskfile.yml（供 `task -g` 自动发现）
  home.file."Taskfile.yml" = {
    source = taskfileGlobal;
    force = true;
  };

  home.packages = with pkgs; [
    go-task
  ];

  home.shellAliases = {
    "tg" = "task -g";
    "tgg" = "task -t ~/Desktop/dotfiles/.taskfile/Taskfile.yml";
  };
}
