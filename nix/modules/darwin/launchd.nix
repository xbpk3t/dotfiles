{ config, pkgs, ... }:

{
  # 定义定时任务
  launchd.daemons.rclone-daily-upload = {
    serviceConfig = {
      Label = "local.rclone.daily.upload";
      ProgramArguments = [
        "${pkgs.go-task}/bin/task"
        "-g"
        "rclone:upload-force"
      ];
      StartCalendarInterval = [
        {
          # 每天凌晨2点执行
          Hour = 2;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/rclone-daily-upload.log";
      StandardErrorPath = "/var/log/rclone-daily-upload.log";
      EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      WorkingDirectory = "/Users/${config.system.primaryUser}";
    };
  };
}
