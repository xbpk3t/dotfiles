{
  pkgs,
  userMeta,
  ...
}: let
  username = userMeta.username;
in {
  modules.networking = {
    singbox.enable = true;
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
      #      StandardOutPath = "/Users/${username}/Library/Logs/rclone-bisync-scratches.log";
      #      StandardErrorPath = "/Users/${username}/Library/Logs/rclone-bisync-scratches.log";
      #      EnvironmentVariables = {
      #        # Include the full PATH to access all user binaries including gh, rclone, etc.
      #        PATH = "/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      #        RCLONE_CONFIG = "/Users/${username}/.config/rclone/rclone.conf";
      #      };
      #      WorkingDirectory = "/Users/${username}";
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

          StandardOutPath = "/Users/${username}/Library/Logs/rclone-sync-docs-images.log";
          StandardErrorPath = "/Users/${username}/Library/Logs/rclone-sync-docs-images.log";
          EnvironmentVariables = {
            # Include the full PATH to access all user binaries including gh, rclone, etc.
            PATH = "/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
            RCLONE_CONFIG = "/Users/${username}/.config/rclone/rclone.conf";
          };
          WorkingDirectory = "/Users/${username}";
        };
      };

      # Determinate Nixd 的 automatic GC 负责 store 级回收，不会自动裁剪旧 system generations。
      # 这里在 Darwin host 层补一条最小化 retention policy；由于 system daemon 本身以 root 运行，
      # 直接执行 nix-collect-garbage 即等价于手动执行 `sudo nix-collect-garbage --delete-older-than 7d`。
      nix-prune-generations = {
        serviceConfig = {
          Label = "local.nix.prune.generations";
          ProgramArguments = [
            "/run/current-system/sw/bin/nix-collect-garbage"
            "--delete-older-than"
            "7d"
          ];
          StartCalendarInterval = [
            {
              Hour = 3;
              Minute = 10;
            }
          ];
          RunAtLoad = true;
          ThrottleInterval = 86400;

          StandardOutPath = "/Users/${username}/Library/Logs/nix-prune-generations.log";
          StandardErrorPath = "/Users/${username}/Library/Logs/nix-prune-generations.log";
          EnvironmentVariables = {
            PATH = "/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          WorkingDirectory = "/Users/${username}";
        };
      };
    };
  };
}
