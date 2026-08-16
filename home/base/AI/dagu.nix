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
      # 主配置（~/.dagu/config.yaml）——应用/daemon 配置，viper 启动时读取。
      # 用 pkgs.formats.yaml 从 Nix attrset 生成真正的 YAML；config.yaml 无 dagu 写回
      # 路径，可安全 home.file 纳管（base.yaml 是 DAG base config，会被 UI base-config
      # 编辑器写回，保持不纳管）。
      ".dagu/config.yaml" = {
        force = true;
        source = (pkgs.formats.yaml { }).generate "dagu-config" {
          # --- 核心：外部 file symlink opt-in ---
          # dagu 2.13 起默认禁用。nix home-manager 的 DAG symlink 目标在 dags_dir 外，
          # 不开则全部不加载。
          dag_discovery = {
            symlinks = true;
          };

          # --- 服务绑定：个人本机，仅 localhost ---
          host = "127.0.0.1";
          port = 8080;

          # --- 认证：个人 localhost 免登录 ---
          # 需要登录防护就删掉这段，保留默认 builtin 并走 /setup
          # （admin 存 user store，不受 config.yaml 只读影响）。
          auth = {
            mode = "none";
          };

          # --- 调度时区：固定东八区，不随系统漂移 ---
          # DAG 的 cron schedule 按此时区计算；不在东八区则改成你的时区。
          tz = "Asia/Shanghai";

          # --- 行为 ---
          check_updates = false; # brew 管理，关启动版本检查
          log_format = "text"; # 显式默认（text / json）
          debug = false; # 显式默认

          # --- 其余保持默认（单节点个人部署） ---
          # paths 由 DAGU_HOME 推导；scheduler / worker / coordinator / queues 走默认；
          # terminal / git_sync / tunnel / webhooks / sse 默认关闭。
        };
      };

      # DAG 定义：逐文件 source = ./dagu/*.yml。HM 单文件会摊平成 <hash>-hm_<file>
      # store 文件，dagu 用 symlink 解析终点 basename 派生 DAG 名 → 名字带 hash 前缀
      # （超 40 字符会校验失败）。待改用"目录源 + 顶层 out-of-store symlink"修复。
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
