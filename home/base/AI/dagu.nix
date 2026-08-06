{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.dagu;
in
{
  options.modules.AI.dagu = with lib; {
    enable = mkEnableOption "Enable Dagu";
  };

  config = lib.mkIf cfg.enable {

    # DAG 定义按文件管理（不整个目录 symlink —— dagu 会在 ~/.dagu/dags 里
    # 维护运行态 .dag.index，目录 symlink 到 nix store 会变成只读导致写入失败）。
    # 每个 yaml 是到 nix store 的不可变 symlink；dagu 只读不写回，安全。

    # home.file 使用扁平 key（".dagu/dags/<file>.yml".source），不能嵌套目录形式，
    # 否则 HM 会把 ".dagu/dags" 当文件条目导致 build 失败的 option 错误。
    # force = true 保留：覆盖 dagu 2.10 首次运行自动生成的 example-*.yaml 中同名占位，
    # 避免被 dagu 自动生成物遮蔽。
    home.file = lib.mkIf pkgs.stdenv.isDarwin {
      ".dagu/dags/deadlink-loop.yml".source = ./dagu/deadlink-loop.yml;
      ".dagu/dags/wiki-digest.yml".source = ./dagu/wiki-digest.yml;
      ".dagu/dags/mac.yml".source = ./dagu/mac.yml;
    };

    # dagu scheduler 常驻（自动按 schedule 触发）—— user 级 launchd agent，因为 dagu 要读
    # ~/.dagu、跑用户 task/mole，不能用 root daemon。由 cfg.enable 天然 gate。
    # HM 的 launchd.agents.<name> 结构 = { enable?, domain?, config }, config 直接放
    # launchd plist 键（Label/ProgramArguments/...）。gui domain 适合需要图形环境的，
    # 这里 dagu 后台调度用 user/Background 即可。
    # dagu 由 brew 管理（/opt/homebrew/bin/dagu），不随 nix 走，所以写绝对路径。
    launchd.agents.dagu-scheduler = lib.mkIf pkgs.stdenv.isDarwin {
      enable = true;
      domain = "user";
      config = {
        Label = "local.dagu.scheduler";
        ProgramArguments = [
          "/opt/homebrew/bin/dagu"
          "scheduler"
          "--dags=${config.home.homeDirectory}/.dagu/dags"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        WorkingDirectory = config.home.homeDirectory;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/dagu-scheduler.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/dagu-scheduler.log";
        EnvironmentVariables = {
          PATH = "/opt/homebrew/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          HOME = config.home.homeDirectory;
        };
      };
    };
  };
}
