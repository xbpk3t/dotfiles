{
  myvars,
  pkgs,
  ...
}: {
  # 使用系统级 daemon 而不是用户级 agent 来避免出现在登录项中
  launchd.daemons = {
    # 系统清理服务 (清理临时文件和缓存)
    system-cleanup = {
      serviceConfig = {
        Label = "local.user.system.cleanup";
        ProgramArguments = [
          "${pkgs.zsh}/bin/zsh"
          "-c"
          ''
            task -g mac-cleanup:cron-task
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
