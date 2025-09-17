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
      # Dock settings (using mkDefault to allow host-specific overrides)
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

      # Finder settings (using mkDefault to allow host-specific overrides)
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

      # Global settings (using mkDefault to allow host-specific overrides)
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

      # Screensaver settings (using mkDefault to allow host-specific overrides)
      screensaver = {
        askForPassword = lib.mkDefault true;
        askForPasswordDelay = lib.mkDefault 0;
      };

      # Trackpad settings (using mkDefault to allow host-specific overrides)
      trackpad = {
        Clicking = lib.mkDefault true;
        TrackpadThreeFingerDrag = lib.mkDefault true;
      };

      # Window manager settings (using mkDefault to allow host-specific overrides)
      WindowManager = {
        AutoHide = lib.mkDefault false;
        EnableStandardClickToShowDesktop = lib.mkDefault true;
        EnableTiledWindowMargins = lib.mkDefault true;
        EnableTilingByEdgeDrag = lib.mkDefault true;
        EnableTilingOptionAccelerator = lib.mkDefault true;
        EnableTopTilingByEdgeDrag = lib.mkDefault true;
        GloballyEnabled = lib.mkDefault false;
        HideDesktop = lib.mkDefault false;
        StandardHideDesktopIcons = lib.mkDefault false;
        StandardHideWidgets = lib.mkDefault false;
        StageManagerHideWidgets = lib.mkDefault false;
      };

      # Mission control settings (using mkDefault to allow host-specific overrides)
      spaces = {
        spans-displays = lib.mkDefault false;
      };

      # Login window settings (using mkDefault to allow host-specific overrides)
      loginwindow = {
        GuestEnabled = lib.mkDefault false;
        DisableConsoleAccess = lib.mkDefault false;
        SHOWFULLNAME = lib.mkDefault true;
        LoginwindowText = lib.mkDefault "Welcome to ${username}'s MacBook Pro";
      };
    };
  };

  # Time zone and locale settings (using mkDefault to allow host-specific overrides)
  time = {
    timeZone = lib.mkDefault "Asia/Shanghai";
  };

  # System state version - this should be set per host, so using mkDefault
  system.stateVersion = lib.mkDefault 6;
}
