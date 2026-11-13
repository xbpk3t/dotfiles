{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.dagu;

  # DAG 由 fleet 共享安装，具体在哪台机器跑由每个 DAG 顶部的 hostname
  # precondition 决定（dagu 没有 runs-on）。新增 ./dagu/*.yml 自动生效。
  dagFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".yml" name) (
    builtins.readDir ./dagu
  );

  # Darwin 用 brew 的 dagu（不随 nix 走）；Linux 用 pkgs.dagu。
  daguBin =
    if pkgs.stdenv.hostPlatform.isDarwin then "/opt/homebrew/bin/dagu" else "${pkgs.dagu}/bin/dagu";

  # 所有 DAG 共用的运行环境：
  # - PATH：task/xurls 在 HM profile，docs-cli 在 go/bin，opencli 在 pnpm/bin，
  #   Darwin 还需要 homebrew（colima/docker/brew）。
  # - hm-session-vars.sh：把 host import 的模块声明的 secrets（OPENAI_API_KEY /
  #   RESEND_TOKEN / CF_R2_* / GITHUB_TOKEN）注入进程，不在 dagu.nix 重复声明。
  #   secret 是 source 时 $(cat ...) 解析的，sops 文件必须已生成。
  schedulerPath = lib.concatStringsSep ":" (
    [
      "${config.home.profileDirectory}/bin"
      "${config.home.homeDirectory}/.nix-profile/bin"
      "${config.home.homeDirectory}/go/bin"
      "${config.home.homeDirectory}/.local/share/pnpm/bin"
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ "/opt/homebrew/bin" ]
    ++ [
      "/run/current-system/sw/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ]
  );

  schedulerScript = pkgs.writeShellScript "dagu-scheduler" ''
    export PATH=${schedulerPath}
    source ${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh
    exec ${daguBin} scheduler --dags=${config.home.homeDirectory}/.dagu/dags
  '';
in
{
  options.modules.AI.dagu = with lib; {
    enable = mkEnableOption "Enable Dagu";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Dagu web UI port (bound to 127.0.0.1).";
    };

    schedulerPort = mkOption {
      type = types.port;
      default = 8090;
      description = "Dagu scheduler health-check port; 0 disables it.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # DAG 定义按文件管理（不整个目录 symlink —— dagu 会在 ~/.dagu/dags 里
      # 维护运行态 .dag.index，目录 symlink 到 nix store 会变成只读导致写入失败）。
      # 每个 yaml 是到 nix store 的不可变 symlink；dagu 只读不写回，安全。
      #
      # home.file 使用扁平 key（".dagu/dags/<file>.yml".source），不能嵌套目录形式，
      # 否则 HM 会把 ".dagu/dags" 当文件条目导致 build 失败的 option 错误。
      # force = true 保留：覆盖 dagu 2.10 首次运行自动生成的 example-*.yaml 中同名占位，
      # 避免被 dagu 自动生成物遮蔽。
      home.file = {
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
            dag_discovery.symlinks = true;

            # --- 服务绑定：个人本机，仅 localhost ---
            host = "127.0.0.1";
            inherit (cfg) port;
            # VPS 上 8090 被 axonhub 占用，host 侧按需覆盖。
            scheduler.port = cfg.schedulerPort;

            # --- 认证：个人 localhost 免登录 ---
            auth.mode = "none";

            # --- 调度时区：固定东八区，不随系统漂移 ---
            tz = "Asia/Shanghai";

            # --- 行为 ---
            check_updates = false; # 版本由 brew / nix 管，关启动版本检查
            log_format = "text";
            debug = false;
          };
        };
      }
      // lib.mapAttrs' (
        name: _:
        lib.nameValuePair ".dagu/dags/${name}" {
          source = ./dagu/${name};
          force = true;
        }
      ) dagFiles;
    })

    # Darwin：user 级 launchd agent 常驻（dagu 要读 ~/.dagu、跑用户 task，不能用 root daemon）。
    (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      launchd.agents.dagu-scheduler = lib.mkIf cfg.enable {
        enable = true;
        domain = "user";
        config = {
          Label = "local.dagu.scheduler";
          ProgramArguments = [ "${schedulerScript}" ];
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 10;
          WorkingDirectory = config.home.homeDirectory;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/dagu-scheduler.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/dagu-scheduler.log";
          EnvironmentVariables = {
            HOME = config.home.homeDirectory;
          };
        };
      };
    })

    # Linux：systemd user service（VPS 已开 linger，无需登录即常驻）。
    (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.dagu-scheduler = lib.mkIf cfg.enable {
        Unit = {
          Description = "Dagu scheduler";
          # sops-nix 的 user service 先把 secret 文件生成到 /run/user/<uid>/secrets.d。
          After = [ "sops-nix.service" ];
        };
        Service = {
          ExecStart = "${schedulerScript}";
          Restart = "always";
          RestartSec = 10;
          WorkingDirectory = config.home.homeDirectory;
          Environment = [ "HOME=${config.home.homeDirectory}" ];
        };
        Install.WantedBy = [ "default.target" ];
      };
    })
  ];
}
