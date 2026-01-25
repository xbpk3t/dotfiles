{
  pkgs,
  myvars,
  ...
}: {
  modules.networking = {
    singbox.enable = true;
  };

  # macOS 作为 deploy 入口；Linux 构建交给 homelab builder
  # 目标：deploy-rs 在 mac 上发起时，不在 mac 本地构建 x86_64-linux
  #       而是把构建任务分发给 homelab，并由 deploy-rs 继续推送 closure 到目标机
  nix = {
    # 开启分布式构建，否则 buildMachines 不会生效
    distributedBuilds = true;
    buildMachines = [
      {
        # homelab 的 SSH 可达地址（目前是 tailnet IP）
        hostName = "100.81.204.63";
        # 声明该 builder 支持的系统类型（这里是 NixOS 节点）
        system = "x86_64-linux";
        # builder 端的 SSH 用户；如需改成普通用户，
        # 需确保该用户在 homelab 上为 trusted user
        sshUser = "root";
        # 该 builder 并行构建上限，避免占满控制面资源
        maxJobs = 4;
      }
    ];
    # 允许 builder 复用 substituters，避免重复构建
    settings.builders-use-substitutes = true;
  };

  # https://mynixos.com/nix-darwin/options/launchd
  # 之所以放在这里，因为不同host的launchd本就不同
  launchd = {
    daemons = {
      #  # 双向同步 scratches 到 R2 (每20分钟一次)
      #  rclone-bisync-scratches = {
      #    serviceConfig = {
      #      Label = "local.rclone.bisync.scratches";
      #      ProgramArguments = [
      #        "${pkgs.go-task}/bin/task"
      #        "-g"
      #        "rclone:bisync-scratches"
      #      ];
      #      StartInterval = 1200; # 每20分钟执行一次
      #      StandardOutPath = "/Users/${myvars.username}/Library/Logs/rclone-bisync-scratches.log";
      #      StandardErrorPath = "/Users/${myvars.username}/Library/Logs/rclone-bisync-scratches.log";
      #      EnvironmentVariables = {
      #        # Include the full PATH to access all user binaries including gh, rclone, etc.
      #        PATH = "/etc/profiles/per-user/${myvars.username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      #        RCLONE_CONFIG = "/Users/${myvars.username}/.config/rclone/rclone.conf";
      #      };
      #      WorkingDirectory = "/Users/${myvars.username}";
      #    };
      #  };

      # 同步 docs 到 R2 (每天一次)
      rclone-sync-docs-images = {
        serviceConfig = {
          Label = "local.rclone.sync.docs-images";
          ProgramArguments = [
            "${pkgs.go-task}/bin/task"
            "-g"
            "rclone:sync-docs-images"
          ];
          StartCalendarInterval = [
            {
              # 每天凌晨3点执行
              Hour = 3;
              Minute = 0;
            }
          ];
          RunAtLoad = true; # 开机时立即执行一次（plist 加载时触发，防止关机错过 sync）
          ThrottleInterval = 86400; # 24小时防重。若不足24小时 → 跳过（避免重复）

          StandardOutPath = "/Users/${myvars.username}/Library/Logs/rclone-sync-docs-images.log";
          StandardErrorPath = "/Users/${myvars.username}/Library/Logs/rclone-sync-docs-images.log";
          EnvironmentVariables = {
            # Include the full PATH to access all user binaries including gh, rclone, etc.
            PATH = "/etc/profiles/per-user/${myvars.username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
            RCLONE_CONFIG = "/Users/${myvars.username}/.config/rclone/rclone.conf";
          };
          WorkingDirectory = "/Users/${myvars.username}";
        };
      };

      # 因为 nh
      nh-clean-all = {
        serviceConfig = {
          Label = "local.nh.clean.all";
          ProgramArguments = [
            "/etc/profiles/per-user/${myvars.username}/bin/nh"
            "clean"
            "all"
            "--keep-since"
            "7d"
            "--keep"
            "5"
          ];
          StartCalendarInterval = [
            {
              Hour = 3;
              Minute = 15;
            }
          ];
          RunAtLoad = true;
          ThrottleInterval = 86400;

          StandardOutPath = "/Users/${myvars.username}/Library/Logs/nh-clean.log";
          StandardErrorPath = "/Users/${myvars.username}/Library/Logs/nh-clean.log";
          EnvironmentVariables = {
            # Avoid PATH entries with spaces (nh clean all bug).
            PATH = "/etc/profiles/per-user/${myvars.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          WorkingDirectory = "/Users/${myvars.username}";
        };
      };
    };
  };
}
