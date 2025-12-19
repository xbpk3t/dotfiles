_: {
  # Power management settings
  # Note: Most power settings in macOS are managed through System Preferences
  # or pmset command line tool. nix-darwin has limited power management options.
  # https://mynixos.com/nix-darwin/options/power

  power = {
    # 系统冻结后自动重启
    restartAfterFreeze = true;
    # error: restarting after power failure is not supported on your machine. Please ensure that `power.restartAfterPowerFailure` is not set.
    # restartAfterPowerFailure = true;

    # restartAfterPowerFailure = false; # 断电后自动开机 [Option is not supported on all devices.] 我的机器不支持该key
    sleep = {
      # 允许电源键触发睡眠（macos本身默认就是短按电源键触发睡眠，所以使用true）
      allowSleepByPowerButton = true;

      # 20 分钟后系统睡眠
      computer = 20;
      # 5 分钟后屏幕关闭
      display = 5;
      # 15 分钟后硬盘睡眠
      # 控制机械盘空转后多久停转(sudo.is (https://www.sudo.is/docs/macos/))。SSD/NVMe 没有马达可停，所以“Put hard disks to sleep” 对内置 SSD 影响极小；多数资料称对 SSD 没收益，甚至可能因少数固件 bug 造成卡 (pcoutlet.com (https://pcoutlet.com/parts/storage-drives/what-is-put-hard-disks-to-sleep-when-possible))
      # 结论：对于SSD来说没用
      harddisk = 15;
    };
  };

  # Power-related launchd services
  #  launchd.daemons = {
  #    # Battery health monitoring
  #    battery-monitor = {
  #      serviceConfig = {
  #        Label = "local.battery.monitor";
  #        ProgramArguments = [
  #          "/bin/bash"
  #          "-c"
  #          ''
  #            # Check battery health and log warnings
  #            battery_info=$(system_profiler SPPowerDataType 2>/dev/null | grep -A 5 "Condition")
  #            if echo "$battery_info" | grep -q "Replace"; then
  #              echo "$(date): WARNING - Battery needs replacement" >> /var/log/battery-monitor.log
  #            fi
  #
  #            # Log current battery cycle count
  #            cycle_count=$(system_profiler SPPowerDataType 2>/dev/null | grep "Cycle Count" | awk '{print $3}')
  #            if [ -n "$cycle_count" ] && [ "$cycle_count" -gt 1000 ]; then
  #              echo "$(date): INFO - Battery cycle count: $cycle_count (high)" >> /var/log/battery-monitor.log
  #            fi
  #          ''
  #        ];
  #        StartInterval = 3600; # Check every hour
  #        StandardOutPath = "/var/log/battery-monitor.log";
  #        StandardErrorPath = "/var/log/battery-monitor.log";
  #      };
  #    };
  #  };

  # Power management user agents (per-user services)
  #  launchd.agents = {
  #    # Improved prevent-sleep service with better conflict handling
  #    prevent-sleep-on-activity = {
  #      serviceConfig = {
  #        Label = "local.power.prevent-sleep";
  #        ProgramArguments = [
  #          "/bin/bash"
  #          "-c"
  #          ''
  #            # Prevent sleep if certain conditions are met
  #            # Check for active downloads, builds, or other long-running processes
  #
  #            # Kill any existing caffeinate processes from this script to avoid conflicts
  #            pkill -f "caffeinate.*prevent-sleep" 2>/dev/null || true
  #
  #            # Check for active downloads (example: aria2, wget, curl)
  #            if pgrep -f "(aria2|wget|curl.*-O)" >/dev/null; then
  #              caffeinate -d -t 3600 -w $$ &  # Prevent display sleep for 1 hour, tied to this process
  #              echo "$(date): Preventing sleep due to active downloads" >> ~/Library/Logs/prevent-sleep.log
  #            fi
  #
  #            # Check for active builds (example: make, cargo, npm, nix)
  #            if pgrep -f "(make|cargo build|npm.*build|nix.*build|darwin-rebuild)" >/dev/null; then
  #              caffeinate -i -t 7200 -w $$ &  # Prevent idle sleep for 2 hours, tied to this process
  #              echo "$(date): Preventing sleep due to active builds" >> ~/Library/Logs/prevent-sleep.log
  #            fi
  #          ''
  #        ];
  #        StartInterval = 900; # Check every 15 minutes (more reasonable)
  #        StandardOutPath = "/Users/${username}/Library/Logs/prevent-sleep.log";
  #        StandardErrorPath = "/Users/${username}/Library/Logs/prevent-sleep.log";
  #      };
  #    };
  #  };
}
