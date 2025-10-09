{...}: {
  services.hyprsunset = {
    enable = true;

    # Shanghai location coordinates
#    settings = {
#      location = {
#        latitude = 31.2;
#        longitude = 121.4;
#      };
#
#      # Temperature settings (correct format)
#      temperature_day = 6500;  # 6500K during day (natural light)
#      temperature_night = 4000; # 4000K during night (warm light)
#
#      # Smooth transitions
#      transition_duration = 3000; # 3 seconds transition
#    };
#
#    # Use systemd target for wayland
#    systemdTarget = "graphical-session.target";

    settings.profile = [
      {
        time = "06:00";
        identity = true;       # 6500K - 自然光
      }
      {
        time = "17:30";
        temperature = 6000;    # 开始微调
      }
      {
        time = "18:00";
        temperature = 5500;    # 开始变暖
      }
      {
        time = "18:30";
        temperature = 5000;    # 渐变过渡
      }
      {
        time = "19:00";
        temperature = 4500;    # 温暖光线
      }
      {
        time = "19:30";
        temperature = 4000;    # 夜间模式
      }
      {
        time = "20:00";
        temperature = 3800;    # 更暖的夜间模式
      }
      {
        time = "22:00";
        temperature = 3600;    # 深度夜间模式
      }
    ];
  };
}
