{
  pkgs,
  username,
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
        StandardOutPath = "/Users/${username}/Library/Logs/rclone-bisync-scratches.log";
        StandardErrorPath = "/Users/${username}/Library/Logs/rclone-bisync-scratches.log";
        EnvironmentVariables = {
          # Include the full PATH to access all user binaries including gh, rclone, etc.
          PATH = "/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          RCLONE_CONFIG = "/Users/${username}/.config/rclone/rclone.conf";
        };
        WorkingDirectory = "/Users/${username}";
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
  };
}
