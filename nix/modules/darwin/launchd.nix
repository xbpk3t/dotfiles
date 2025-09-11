{
  config,
  pkgs,
  ...
}: {
  # 双向同步 scratches 到 R2 (每20分钟一次)
  launchd.daemons.rclone-bisync-scratches = {
    serviceConfig = {
      Label = "local.rclone.bisync.scratches";
      ProgramArguments = [
        "${pkgs.go-task}/bin/task"
        "-g"
        "rclone:bisync-scratches"
      ];
      StartInterval = 1200; # 每20分钟执行一次
      StandardOutPath = "/var/log/rclone-bisync-scratches.log";
      StandardErrorPath = "/var/log/rclone-bisync-scratches.log";
      EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      WorkingDirectory = "/Users/${config.system.primaryUser}";
    };
  };

  # 同步 docs 到 R2 (每天一次)
  launchd.daemons.rclone-sync-docs = {
    serviceConfig = {
      Label = "local.rclone.sync.docs";
      ProgramArguments = [
        "${pkgs.go-task}/bin/task"
        "-g"
        "rclone:sync-docs"
      ];
      StartCalendarInterval = [
        {
          # 每天凌晨3点执行
          Hour = 3;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/rclone-sync-docs.log";
      StandardErrorPath = "/var/log/rclone-sync-docs.log";
      EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      WorkingDirectory = "/Users/${config.system.primaryUser}";
    };
  };
}
