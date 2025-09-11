{
  pkgs,
  ...
}: {
  # 双向同步 scratches 到 R2 (每20分钟一次)
  systemd.user.services.rclone-bisync-scratches = {
    description = "Rclone bisync scratches to R2";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.go-task}/bin/task -g rclone:bisync-scratches";
      WorkingDirectory = "%h";
      Environment = [
        "PATH=/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"
      ];
    };
    wantedBy = ["default.target"];
  };

  systemd.user.timers.rclone-bisync-scratches = {
    description = "Run rclone bisync scratches every 20 minutes";
    timerConfig = {
      OnCalendar = "*:0/20";
      Persistent = true;
    };
    wantedBy = ["timers.target"];
  };

  # 同步 docs 到 R2 (每天一次)
  systemd.user.services.rclone-sync-docs = {
    description = "Rclone sync docs to R2";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.go-task}/bin/task -g rclone:sync-docs";
      WorkingDirectory = "%h";
      Environment = [
        "PATH=/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"
      ];
    };
    wantedBy = ["default.target"];
  };

  systemd.user.timers.rclone-sync-docs = {
    description = "Run rclone sync docs daily";
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
    wantedBy = ["timers.target"];
  };
}
