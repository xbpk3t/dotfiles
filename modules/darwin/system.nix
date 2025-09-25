{
  username,
  lib,
  ...
}: {
  # Shared macOS system preferences with default values
  # Host-specific configurations can override these defaults
  system = {
    # Set the primary user for this specific machine (can be overridden)
    primaryUser = lib.mkDefault username;

    # System defaults with mkDefault to allow host-specific overrides
    defaults = {
      # Dock settings
      dock = {
        tilesize = lib.mkDefault 32; # Smaller dock size as requested
        magnification = lib.mkDefault false;
        largesize = lib.mkDefault 48; # Adjusted proportionally
        orientation = lib.mkDefault "left";
        autohide = lib.mkDefault true;
        autohide-delay = lib.mkDefault 0.0;
        autohide-time-modifier = lib.mkDefault 0.0;
        show-recents = lib.mkDefault false;
        persistent-apps = lib.mkDefault [];
        static-only = lib.mkDefault false;
        launchanim = lib.mkDefault false;
      };

      # Finder settings
      finder = {
        AppleShowAllFiles = lib.mkDefault true;
        ShowPathbar = lib.mkDefault true;
        ShowStatusBar = lib.mkDefault true;
        FXDefaultSearchScope = lib.mkDefault "SCcf";
        FXPreferredViewStyle = lib.mkDefault "clmv"; # Column view
        CreateDesktop = lib.mkDefault false;
        FXEnableExtensionChangeWarning = lib.mkDefault false;
        _FXShowPosixPathInTitle = lib.mkDefault true;
        QuitMenuItem = lib.mkDefault true;
        AppleShowAllExtensions = lib.mkDefault true;
      };

      # Global settings
      NSGlobalDomain = {
        # Time configuration
        AppleICUForce24HourTime = lib.mkDefault true;
        AppleInterfaceStyle = lib.mkDefault null; # Dark or null for light mode

        # Keyboard settings
        KeyRepeat = lib.mkDefault 2; # Set to fastest
        InitialKeyRepeat = lib.mkDefault 15;
        AppleKeyboardUIMode = lib.mkDefault 3;

        # Finder settings (removed duplicate AppleShowAllExtensions - already set in finder section)
        NSNavPanelExpandedStateForSaveMode = lib.mkDefault true;
        NSNavPanelExpandedStateForSaveMode2 = lib.mkDefault true;
        PMPrintingExpandedStateForPrint = lib.mkDefault true;
        PMPrintingExpandedStateForPrint2 = lib.mkDefault true;

        # Trackpad settings
        "com.apple.trackpad.scaling" = lib.mkDefault 1.5;
        "com.apple.mouse.tapBehavior" = lib.mkDefault 1;
        "com.apple.trackpad.enableSecondaryClick" = lib.mkDefault true;

        # Interface settings
        ApplePressAndHoldEnabled = lib.mkDefault false;
        AppleScrollerPagingBehavior = lib.mkDefault false;
        # 用来保证IDEA里多个项目设置为在同一窗口内以 Tab 形式打开
        AppleWindowTabbingMode = lib.mkDefault "always";
        NSAutomaticWindowAnimationsEnabled = lib.mkDefault false;
        NSUseAnimatedFocusRing = lib.mkDefault false;

        # Automatic spelling correction
        NSAutomaticSpellingCorrectionEnabled = lib.mkDefault false;
        NSAutomaticCapitalizationEnabled = lib.mkDefault false;
        NSAutomaticDashSubstitutionEnabled = lib.mkDefault false;
        NSAutomaticPeriodSubstitutionEnabled = lib.mkDefault false;
        NSAutomaticQuoteSubstitutionEnabled = lib.mkDefault false;
      };

      # Screensaver settings
      screensaver = {
        askForPassword = lib.mkDefault true;
        askForPasswordDelay = lib.mkDefault 0;
      };

      # Trackpad settings
      trackpad = {
        ActuationStrength = lib.mkDefault 0;
        Clicking = lib.mkDefault true;
        Dragging = lib.mkDefault false;
        # 启用三指拖拽功能
        TrackpadThreeFingerDrag = lib.mkDefault true;

        FirstClickThreshold = lib.mkDefault 0;
        SecondClickThreshold = lib.mkDefault 1;
        # 启用右键点击
        TrackpadRightClick = lib.mkDefault true;
        # 三指轻点触发 Look up
        TrackpadThreeFingerTapGesture = lib.mkDefault 2;
      };

      # Window manager settings
      WindowManager = {
        # 自动隐藏 Stage Manager 条
        AutoHide = lib.mkDefault false;
        # 开启点击壁纸显示桌面
        EnableStandardClickToShowDesktop = lib.mkDefault true;
        # 平铺窗口时启用边距
        EnableTiledWindowMargins = lib.mkDefault true;
        # 启用拖动窗口到屏幕边缘进行平铺
        EnableTilingByEdgeDrag = lib.mkDefault true;
        # 启用按住 Alt 键进行窗口平铺
        EnableTilingOptionAccelerator = lib.mkDefault true;
        # 启用拖动窗口到菜单栏进行全屏填充
        EnableTopTilingByEdgeDrag = lib.mkDefault true;
        # 禁用Stage Manager
        GloballyEnabled = lib.mkDefault false;
        HideDesktop = lib.mkDefault false;
        # 隐藏桌面图标
        StandardHideDesktopIcons = lib.mkDefault true;
        # 隐藏桌面小部件
        StandardHideWidgets = lib.mkDefault true;
        # 隐藏 Stage Manager 中的小部件
        StageManagerHideWidgets = lib.mkDefault true;
        # window分组策略
        AppWindowGroupingBehavior = true;
      };

      # Mission control settings
      spaces = {
        spans-displays = lib.mkDefault false;
      };

      # Login window settings
      loginwindow = {
        autoLoginUser = lib.mkDefault username;
        GuestEnabled = lib.mkDefault false;
        DisableConsoleAccess = lib.mkDefault false;
        SHOWFULLNAME = lib.mkDefault true;
        LoginwindowText = lib.mkDefault "";
      };

      SoftwareUpdate = {
        AutomaticallyInstallMacOSUpdates = lib.mkDefault false;
      };

      controlcenter = {
        # Menubar上不展示以下服务
        AirDrop = lib.mkDefault false;
        NowPlaying = lib.mkDefault false;
        Display = lib.mkDefault false;
        Sound = lib.mkDefault false;
        BatteryShowPercentage = lib.mkDefault false;
        FocusModes = lib.mkDefault false;

        Bluetooth = lib.mkDefault true;
      };

      # https://mynixos.com/nix-darwin/options/system.defaults.screencapture
      screencapture = {
        type = "png";
      };

      iCal = {
        "first day of week" = "Monday";
        "TimeZone support enabled" = true;
        CalendarSidebarShown = true;
      };

      ActivityMonitor = {
        # Dock 图标显示网络使用情况
        IconType = 2;
        # 打开时显示主窗口
        OpenMainWindow = true;
        # 100显示所有进程；101：显示所有进程（按层级结构）；102：仅显示当前用户的进程；
        ShowCategory = 101;
        # 按 CPU 使用率排序（需确认具体列名）
        SortColumn = "CPUUsage";
        # 降序排序
        SortDirection = 0;
      };
    };
  };

  # Time zone and locale settings
  time = {
    timeZone = lib.mkDefault "Asia/Shanghai";
  };

  # System state version - this should be set per host, so using mkDefault
  system.stateVersion = lib.mkDefault 6;
}
