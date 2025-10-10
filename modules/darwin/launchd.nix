{
  myvars,
  pkgs,
  ...
}: {
  # 使用系统级 daemon 而不是用户级 agent 来避免出现在登录项中
  launchd.daemons = {
    # 双向同步 scratches 到 R2 (每20分钟一次)
    rclone-bisync-scratches = {
      serviceConfig = {
        Label = "local.rclone.bisync.scratches";
        ProgramArguments = [
          "${pkgs.go-task}/bin/task"
          "-g"
          "rclone:bisync-scratches"
        ];
        StartInterval = 1200; # 每20分钟执行一次
        StandardOutPath = "/Users/${myvars.username}/Library/Logs/rclone-bisync-scratches.log";
        StandardErrorPath = "/Users/${myvars.username}/Library/Logs/rclone-bisync-scratches.log";
        EnvironmentVariables = {
          # Include the full PATH to access all user binaries including gh, rclone, etc.
          PATH = "/etc/profiles/per-user/${myvars.username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          RCLONE_CONFIG = "/Users/${myvars.username}/.config/rclone/rclone.conf";
        };
        WorkingDirectory = "/Users/${myvars.username}";
      };
    };

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

    # 系统清理服务 (清理临时文件和缓存)
    system-cleanup = {
      serviceConfig = {
        Label = "local.user.system.cleanup";
        ProgramArguments = [
          "${pkgs.zsh}/bin/zsh"
          "-c"
          ''
            # 系统清理脚本
            TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
            LOG_FILE="/Users/${myvars.username}/Library/Logs/system-cleanup.log"

            echo "$TIMESTAMP: Starting system cleanup" >> "$LOG_FILE"

            # 清理 macOS 缓存文件 (注意：只清理安全的缓存)
            find "/Users/${myvars.username}/Library/Caches" -type f -mtime +30 -delete >> "$LOG_FILE" 2>&1

            # 清理旧的日志文件
            find "/Users/${myvars.username}/Library/Logs" -name "*.log" -mtime +30 -size +10M -delete >> "$LOG_FILE" 2>&1

            task -g brew:cleanup

            task -g pnpm:cleanup

            echo "$TIMESTAMP: System cleanup completed" >> "$LOG_FILE"
          ''
        ];
        StartCalendarInterval = [
          {
            # 每周日凌晨2点执行
            Weekday = 0;
            Hour = 2;
            Minute = 0;
          }
        ];
        RunAtLoad = false;
        StandardOutPath = "/Users/${myvars.username}/Library/Logs/system-cleanup.log";
        StandardErrorPath = "/Users/${myvars.username}/Library/Logs/system-cleanup.log";
        EnvironmentVariables = {
          PATH = "/etc/profiles/per-user/${myvars.username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          USER = myvars.username;
        };
        WorkingDirectory = "/Users/${myvars.username}";
      };
    };
  };
}
