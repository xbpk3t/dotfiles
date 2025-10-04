{pkgs, ...}: {
  # Hypridle configuration - 系统空闲管理
  # 配置熄屏、锁屏和休眠行为
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        #        # 锁屏后执行命令 - 使用配置好的 swaylock
        #        lock_cmd = "swaylock";
        #        # 休眠前执行命令 - 使用配置好的 swaylock
        #        before_sleep_cmd = "swaylock";
        # 唤醒后执行命令 - 恢复显示器
        after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        # 忽略 DBus 抑制（让系统管理器处理电源管理）
        ignore_dbus_inhibit = false;
        # 忽略 systemd 抑制
        ignore_systemd_inhibit = false;
      };

      listener = [
        # 5 分钟 (300 秒) 后降低亮度
        {
          timeout = 300;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }

        # 10 分钟 (600 秒) 后关闭显示器
        {
          timeout = 600;
          on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        }

        # 10 分钟 (600 秒) 后锁定屏幕 - 调整时间使其更合理
        #        {
        #          timeout = 600;
        #          on-timeout = "swaylock";
        #        }
      ];
    };
  };
}
