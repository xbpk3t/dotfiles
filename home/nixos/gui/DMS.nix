{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.shell.dms;
in {
  options.modules.desktop.shell.dms = {
    enable = mkEnableOption "DMS service";
  };

  config = mkIf cfg.enable {
    programs.dankMaterialShell = {
      enable = true;

      # 启用 systemd 自动启动
      enableSystemd = true;

      # 启用各种功能模块
      # 系统监控
      enableSystemMonitoring = true;

      # 剪贴板历史
      enableClipboard = true;

      # VPN 支持
      enableVPN = true;

      # 亮度控制
      enableBrightnessControl = true;

      # 夜间模式
      enableNightMode = true;

      # 动态主题
      enableDynamicTheming = true;

      # 音频可视化
      enableAudioWavelength = true;

      # 日历事件支持
      enableCalendarEvents = true;

      # niri 集成配置
      niri = {
        # 启用 DMS 的 niri 快捷键绑定
        enableKeybinds = true;

        # 禁用 DMS 在 niri 启动时自动运行（使用 systemd 服务管理）
        # 注意：如果同时启用 enableSystemd 和 enableSpawn，会导致两个 DMS 实例同时运行
        enableSpawn = false;
      };

      # 默认设置配置
      # 这些设置会在首次运行时生成，之后可以通过 DMS 的设置界面修改
      default.settings = {
        currentThemeName = "blue";
        customThemeFile = "";
        matugenScheme = "scheme-tonal-spot";
        runUserMatugenTemplates = true;
        dankBarTransparency = 1;
        dankBarWidgetTransparency = 1;
        popupTransparency = 1;
        dockTransparency = 1;
        use24HourClock = true;
        useFahrenheit = false;
        nightModeEnabled = false;
        weatherLocation = "Shanghai";
        weatherCoordinates = "31.2304,-121.4737";
        useAutoLocation = true;
        weatherEnabled = true;
        showLauncherButton = true;
        showWorkspaceSwitcher = true;
        showFocusedWindow = true;
        showWeather = true;
        showMusic = true;
        showClipboard = true;
        showCpuUsage = true;
        showMemUsage = true;
        showCpuTemp = true;
        showGpuTemp = true;
        selectedGpuIndex = 0;
        enabledGpuPciIds = [
        ];
        showSystemTray = true;
        showClock = true;
        showNotificationButton = true;
        showBattery = true;
        showControlCenterButton = true;
        controlCenterShowNetworkIcon = true;
        controlCenterShowBluetoothIcon = true;
        controlCenterShowAudioIcon = true;
        controlCenterWidgets = [
          {
            id = "volumeSlider";
            enabled = true;
            width = 50;
          }
          {
            id = "brightnessSlider";
            enabled = true;
            width = 50;
          }
          {
            id = "wifi";
            enabled = true;
            width = 50;
          }
          {
            id = "bluetooth";
            enabled = true;
            width = 50;
          }
          {
            id = "audioOutput";
            enabled = true;
            width = 50;
          }
          {
            id = "audioInput";
            enabled = true;
            width = 50;
          }
          {
            id = "nightMode";
            enabled = true;
            width = 50;
          }
          {
            id = "darkMode";
            enabled = true;
            width = 50;
          }
        ];
        showWorkspaceIndex = true;
        showWorkspacePadding = true;
        showWorkspaceApps = true;
        maxWorkspaceIcons = 3;
        workspacesPerMonitor = true;
        workspaceNameIcons = {
        };
        waveProgressEnabled = false;
        clockCompactMode = false;
        focusedWindowCompactMode = false;
        runningAppsCompactMode = true;
        runningAppsCurrentWorkspace = false;
        clockDateFormat = "ddd MMM d";
        lockDateFormat = "ddd MMM d";
        mediaSize = 1;
        dankBarLeftWidgets = [
          "launcherButton"
          "workspaceSwitcher"
          "focusedWindow"
        ];
        dankBarCenterWidgets = [
        ];
        dankBarRightWidgets = [
          "systemTray"
          "clipboard"
          "cpuUsage"
          "memUsage"
          "notificationButton"
          "battery"
          "controlCenterButton"
          {
            id = "clock";
            enabled = true;
          }
        ];
        appLauncherViewMode = "list";
        spotlightModalViewMode = "list";
        networkPreference = "auto";
        iconTheme = "System Default";
        launcherLogoMode = "apps";
        launcherLogoCustomPath = "";
        launcherLogoColorOverride = "";
        launcherLogoColorInvertOnMode = false;
        launcherLogoBrightness = {
        };
        launcherLogoContrast = 1;
        launcherLogoSizeOffset = 0;
        fontFamily = "Inter";
        monoFontFamily = "Fira Code";
        fontWeight = 400;
        fontScale = 1;
        dankBarFontScale = 1;
        notepadUseMonospace = true;
        notepadFontFamily = "";
        notepadFontSize = 14;
        notepadShowLineNumbers = false;
        notepadTransparencyOverride = -1;
        notepadLastCustomTransparency = {
        };
        gtkThemingEnabled = false;
        qtThemingEnabled = false;
        showDock = false;
        dockAutoHide = false;
        dockGroupByApp = false;
        dockOpenOnOverview = false;
        dockPosition = 1;
        dockSpacing = 4;
        dockBottomGap = 0;
        cornerRadius = 12;
        notificationOverlayEnabled = false;
        dankBarAutoHide = true;
        dankBarOpenOnOverview = false;
        dankBarVisible = true;
        dankBarSpacing = 4;
        dankBarBottomGap = 0;
        dankBarInnerPadding = 4;
        dankBarSquareCorners = true;
        dankBarNoBackground = false;
        dankBarGothCornersEnabled = false;
        dankBarBorderEnabled = false;
        dankBarBorderColor = "surfaceText";
        dankBarBorderOpacity = 1;
        dankBarBorderThickness = 1;
        dankBarPosition = 0;
        lockScreenShowPowerActions = true;
        hideBrightnessSlider = false;
        widgetBackgroundColor = "sch";
        surfaceBase = "s";
        notificationTimeoutLow = 5000;
        notificationTimeoutNormal = 5000;
        notificationTimeoutCritical = 0;
        notificationPopupPosition = 0;
        osdAlwaysShowValue = false;
        screenPreferences = {
        };
        animationSpeed = 0;
      };
    };

    # [DMS fails to start and reports: the error module "QtMultimedia" is not installed · Issue #420 · AvengeMedia/DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell/issues/420)
    home.packages = [pkgs.kdePackages.qtmultimedia];
  };
}
