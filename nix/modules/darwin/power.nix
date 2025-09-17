# Darwin power management configuration
# macOS-specific power settings and optimizations
{...}: {
  # Power management settings
  # Note: Most power settings in macOS are managed through System Preferences
  # or pmset command line tool. nix-darwin has limited power management options.

  power = {
    restartAfterFreeze = true; # 系统冻结后自动重启
    restartAfterPowerFailure = false; # 断电后自动开机
    sleep = {
      allowSleepByPowerButton = true; # 允许电源键触发睡眠（macos本身默认就是短按电源键触发睡眠，所以使用true）
      computer = 20; # 20 分钟后系统睡眠
      display = 5; # 5 分钟后屏幕关闭
      harddisk = 15; # 15 分钟后硬盘睡眠
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
