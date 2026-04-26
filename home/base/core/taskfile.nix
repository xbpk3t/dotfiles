{
  pkgs,
  mylib,
  ...
}: {
  # !!! 注意这里对于 taskfile 的设计。核心需求在于：可以同时保证在 tg 和 tgg 调用，具体来说：
  ## 1、保证 dotfiles 项目内的 .taskfile folder 独立可用
  ## 2、保证分发到 global taskfile之后，也可用
  # 可以看到核心问题在于，在保证项目内可调用情况下，放到 global taskfile里，需要给每层 includes taskfile 都加一个 taskfile 的 prefix，否则层级就不对了。那怎么解决呢？
  # 之前尝试了用 jq 来在 home.file 里根据入口的 taskfile.yml，给所有 includes里都塞一个taskfile，作为prefix。但是这个修改是脆弱的，果然在修改taskfile.yml写法之后，这个就挂了。之后决定换个写法，这个方案是最简易的。我们在 ~ 下面的 taskfile 只需要 includes我们这个 .taskfile/Taskfile.yml 就行了，这样其实这两个taskfile，从功能来说，其实就合二为一了。

  # 分发 .taskfile 目录（供 includes 解析到子 Taskfile）
  home.file."taskfile" = {
    source = mylib.relativeToRoot ".taskfile";
    recursive = true;
    force = true;
  };

  # 分发由 Nix 生成的全局入口 Taskfile.yml（供 `task -g` 自动发现）
  home.file."Taskfile.yml" = {
    source = pkgs.writeText "taskfile-global.yml" ''
      ---
      version: "3"

      includes:
        all:
          taskfile: taskfile/Taskfile.yml
          flatten: true
    '';
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
