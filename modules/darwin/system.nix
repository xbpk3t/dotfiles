{myvars, ...}: {
  # Shared macOS system preferences with default values
  # Host-specific configurations can override these defaults
  system = {
    # Set the primary user for this specific machine (can be overridden)
    primaryUser = myvars.username;

    defaults = {
      # Dock settings
      dock = {
        # Smaller dock size as requested
        tilesize = 2;
        magnification = false;

        # Adjusted proportionally
        # 16 < size < 128
        largesize = 16;
        orientation = "left";
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        show-recents = false;
        persistent-apps = [];
        static-only = false;
        launchanim = false;
      };

      # Finder settings
      finder = {
        AppleShowAllFiles = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        FXDefaultSearchScope = "SCcf";
        FXPreferredViewStyle = "clmv"; # Column view
        CreateDesktop = false;
        FXEnableExtensionChangeWarning = false;
        _FXShowPosixPathInTitle = true;
        QuitMenuItem = true;
        AppleShowAllExtensions = true;
      };

      # Global settings
      NSGlobalDomain = {
        # Time configuration
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark"; # Dark or null for light mode

        # Keyboard settings
        KeyRepeat = 2; # Set to fastest
        InitialKeyRepeat = 15;
        AppleKeyboardUIMode = 3;

        # Finder settings (removed duplicate AppleShowAllExtensions - already set in finder section)
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;

        # Trackpad settings
        "com.apple.trackpad.scaling" = 1.5;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.trackpad.enableSecondaryClick" = true;

        # Interface settings
        ApplePressAndHoldEnabled = false;
        AppleScrollerPagingBehavior = false;
        # 用来保证IDEA里多个项目设置为在同一窗口内以 Tab 形式打开
        AppleWindowTabbingMode = "always";
        NSAutomaticWindowAnimationsEnabled = false;
        NSUseAnimatedFocusRing = false;

        # Automatic spelling correction
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
      };

      # Screensaver settings
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      # Trackpad settings
      trackpad = {
        ActuationStrength = 0;
        Clicking = true;
        Dragging = false;
        # 启用三指拖拽功能
        TrackpadThreeFingerDrag = true;

        FirstClickThreshold = 0;
        SecondClickThreshold = 1;
        # 启用右键点击
        TrackpadRightClick = true;
        # 三指轻点触发 Look up
        TrackpadThreeFingerTapGesture = 2;
      };

      # Window manager settings
      WindowManager = {
        # 自动隐藏 Stage Manager 条
        AutoHide = false;
        # 开启点击壁纸显示桌面
        EnableStandardClickToShowDesktop = true;
        # 平铺窗口时启用边距
        EnableTiledWindowMargins = true;
        # 启用拖动窗口到屏幕边缘进行平铺
        EnableTilingByEdgeDrag = true;
        # 启用按住 Alt 键进行窗口平铺
        EnableTilingOptionAccelerator = true;
        # 启用拖动窗口到菜单栏进行全屏填充
        EnableTopTilingByEdgeDrag = true;
        # 禁用Stage Manager
        GloballyEnabled = false;
        HideDesktop = false;
        # 隐藏桌面图标
        StandardHideDesktopIcons = true;
        # 隐藏桌面小部件
        StandardHideWidgets = true;
        # 隐藏 Stage Manager 中的小部件
        StageManagerHideWidgets = true;
        # window分组策略
        AppWindowGroupingBehavior = true;
      };

      # Mission control settings
      spaces = {
        spans-displays = false;
      };

      # Login window settings
      loginwindow = {
        # autoLoginUser 会在启用 FileVault 或公司策略时被系统拒绝，并降低安全性。但是个人使用可以开启该配置项。
        autoLoginUser = myvars.username;
        GuestEnabled = false;
        DisableConsoleAccess = false;
        SHOWFULLNAME = true;
        LoginwindowText = "";
      };

      SoftwareUpdate = {
        AutomaticallyInstallMacOSUpdates = false;
      };

      controlcenter = {
        # Menubar上不展示以下服务
        AirDrop = false;
        NowPlaying = false;
        Display = false;
        Sound = false;
        BatteryShowPercentage = false;
        FocusModes = false;

        Bluetooth = true;
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

  # TODO nightlight 本身尚未提供相应配置项，可能需要用该cli预配置
  # https://github.com/smudge/nightlight
  # https://mynixos.com/nixpkgs/package/nightlight

  # Time zone and locale settings
  time = {
    timeZone = myvars.timeZone;
  };

  system.stateVersion = 6;
}
