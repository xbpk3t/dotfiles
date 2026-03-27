{
  userMeta,
  timeMeta,
  ...
}: let
  username = userMeta.username;
  timeZone = timeMeta.timeZone;
in {
  # Shared macOS system preferences with default values
  # Host-specific configurations can override these defaults
  # 不需要去查什么Darwin的SystemPreferences，只需要去查nix-darwin的文档即可。因为并非所有配置项，都提供了nix配置项。
  system = {
    # Set the primary user for this specific machine (can be overridden)
    primaryUser = username;

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

        # Hot Corner
        # Mac的hot corner其实挺傻的（非常干扰，导致误操作），所以全部取消掉
        # https://mynixos.com/nix-darwin/option/system.defaults.dock.wvous-bl-corner
        wvous-tl-corner = 1; # top-left
        wvous-tr-corner = 1; # top-right
        wvous-bl-corner = 1; # bottom-left
        wvous-br-corner = 1; # bottom-right
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
      # https://mynixos.com/nix-darwin/options/system.defaults.NSGlobalDomain
      NSGlobalDomain = {
        # Time configuration
        AppleICUForce24HourTime = true;

        # 设置全局 Dark Mode
        # Dark or null for light mode
        AppleInterfaceStyle = "Dark";

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

      # https://mynixos.com/nix-darwin/option/system.defaults.CustomUserPreferences
      CustomUserPreferences = {
        # 禁用 Siri
        # https://apple.stackexchange.com/questions/462525/disable-siri-fully-via-terminal-ventura
        "com.apple.assistant.support" = {
          "Assistant Enabled" = false;
        };
        "com.apple.Siri" = {
          StatusMenuVisible = false;
          UserHasDeclinedEnable = true;
        };

        # system.defaults.screencapture 只覆盖了常用项。在 CustomUserPreferences 里配置 CMD+Shift+5 的具体配置项
        "com.apple.screencapture" = {
          # 记住上次选区
          "save-selections" = true;
          # 例：是否包含鼠标指针（按需）
          "showsCursor" = false;
        };

        # 怎么关闭 mac 的触摸板？
        # 在Accessibility中，勾选“有鼠标或无线触控板时忽略内置触控板”。需要注意的是，只有 magic mouse 才能识别，其他鼠标识别不出来，无法关闭触摸板。
        # https://github.com/nix-darwin/nix-darwin/issues/1572/
        #        "com.apple.AppleMultitouchTrackpad" = {
        #          USBMouseStopsTrackpad = 1;
        #        };
        #        "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
        #          USBMouseStopsTrackpad = 1;
        #        };
      };

      # https://mynixos.com/nix-darwin/option/system.defaults.CustomSystemPreferences
      CustomSystemPreferences = {
        ".GlobalPreferences" = {
          # 注销（0s表示自动注销）
          "com.apple.autologout.AutoLogOutDelay" = 0;
        };
      };

      # Screensaver settings
      screensaver = {
        # 进入屏保后，需要输入密码，才能恢复
        askForPassword = true;
        # 0 秒，立刻要密码
        askForPasswordDelay = 0;
      };

      # Trackpad settings
      trackpad = {
        ActuationStrength = 0;
        Clicking = true;
        Dragging = false;

        # !!!
        # 启用三指拖拽功能
        # 【三指拖移功能】可以直接拖拽窗口、选中文本、图片，相当于之前单指点按的所有操作的快捷操作。设置之后，需要使用四指进行窗口切换。
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
        # window分组策略
        AppWindowGroupingBehavior = true;

        # 自动隐藏 Stage Manager 条
        AutoHide = false;
        # 开启点击壁纸显示桌面
        EnableStandardClickToShowDesktop = true;

        # 平铺窗口时启用边距
        # Tiled windows have margins (Dock & Desktop -> window) -> Turn off
        EnableTiledWindowMargins = false;

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
      };

      # Mission control settings
      spaces = {
        spans-displays = false;
      };

      # Login window settings
      loginwindow = {
        # autoLoginUser 会在启用 FileVault 或公司策略时被系统拒绝，并降低安全性。但是个人使用可以开启该配置项。
        autoLoginUser = username;
        GuestEnabled = false;
        DisableConsoleAccess = false;
        SHOWFULLNAME = true;
        LoginwindowText = "";
      };

      SoftwareUpdate = {
        # 是否自动更新MacOS
        AutomaticallyInstallMacOSUpdates = false;
      };

      # Control Center
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
      # 仅作配置。日常还是使用 Xnip 作为主力截图工具，因为
      ## 1、不支持 直接标注（需要截图后，点击右下角出现的缩略图，进入编辑/标注。或者在Finder中Markup标注（这就需要文件必须存到本地之后，才能操作。不能直接放到Clipboard里））
      ## 2、不支持 滚动截图
      # Shift + Command + 3 (全屏)、
      # Shift + Command + 4 (选区域/窗口)
      # Shift + Command + 5 (打开截屏工具栏，可录屏)
      # 如果按住Control 可以直接复制到Clipboard
      screencapture = {
        type = "png";
        # 或 "clipboard" / "preview" ...
        target = "file";
        location = "/Users/${username}/Downloads";
        disable-shadow = true;
        include-date = false;
        show-thumbnail = false;
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

      # https://mynixos.com/nix-darwin/options/system.defaults.menuExtraClock
      menuExtraClock = {
        ShowSeconds = false;
        Show24Hour = true;
        ShowAMPM = false;
        ShowDayOfWeek = false;
      };
    };

    # 内置 Hearing功能
    # Hearing 目前在ControlCenter里不支持，所以需要通过 activationScript 来实现
    activationScripts.controlCenterHearing.text = ''
      # 先确认一下：切 UI 之后一般可以在这里看到对应 key
      # /usr/bin/defaults -currentHost read com.apple.controlcenter | /usr/bin/grep -i hearing || true

      # 常见：18=显示在菜单栏，24=隐藏（和 Sound / AirDrop 一致）
      /usr/bin/defaults -currentHost write com.apple.controlcenter Hearing -int 18
    '';

    # https://github.com/nix-darwin/nix-darwin/issues/1421
    # https://ss64.com/mac/pmset.html
    activationScripts.pmset.text = builtins.readFile ./pmset.sh;
  };

  # MAYBE: Date format (Language -> Date and number formats) -> Year-Month-Day (other than Year/Month-Day). 查了一下目前确实没有这个配置项，用来修改默认 date format

  # https://github.com/smudge/nightlight
  # https://mynixos.com/nixpkgs/package/nightlight

  # Time zone and locale settings
  time = {
    inherit timeZone;
  };

  system.stateVersion = 6;
}
