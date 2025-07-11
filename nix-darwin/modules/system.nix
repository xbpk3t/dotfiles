{ pkgs, username, ... }:

{
  # macOS 系统偏好设置 - 从 Taskfile 迁移
  system.primaryUser = username;
  system.defaults = {
    # Dock 设置
    dock = {
      tilesize = 4;
      magnification = false;
      largesize = 32;
      orientation = "left";
      autohide = true;
      autohide-delay = 0.0;
      # 移除所有默认应用
      persistent-apps = [];
    };

    # Finder 设置
    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXDefaultSearchScope = "SCcf";
      FXPreferredViewStyle = "clmv"; # 默认列视图
    };

    # 全局设置
    NSGlobalDomain = {
      # 时间配置
      # "loginwindow.GuestEnabled" = false; # 此选项在新版本中不可用
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";

      # 键盘设置
      KeyRepeat = 2; # 设置为最快
      InitialKeyRepeat = 15;
      AppleKeyboardUIMode = 3;

      # Finder 设置
      AppleShowAllExtensions = true;

      # 触控板设置
      # "com.apple.mouse.tapBehavior" = 1; # 此选项在新版本中不可用
    };

    # 桌面服务设置
    ".GlobalPreferences" = {
      # "com.apple.mouse.tapBehavior" = 1; # 此选项在新版本中不可用
    };

    # 其他系统设置
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    # 触控板设置
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    # 桌面服务设置 - 避免在网络卷上创建 .DS_Store 文件
    # desktopservices = {
    #   DSDontWriteNetworkStores = true;
    # }; # 此选项在新版本中不可用
  };

  # 启用 zsh shell
  programs.zsh.enable = true;

  # 系统版本
  system.stateVersion = 6;
}
