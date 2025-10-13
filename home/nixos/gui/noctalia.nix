{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.desktop.shell.noctalia;
in {
  # Noctalia Shell 配置模块
  # 使用 cfg 模式实现条件开关
  options.modules.desktop.shell.noctalia = {
    enable = mkEnableOption "noctalia shell";
  };

  config = mkIf cfg.enable {
    # Install noctalia package
    #  home.packages = with pkgs; [
    #    inputs.noctalia.packages.${pkgs.system}.default
    #  ];

    # configure options
    programs.noctalia-shell = {
      enable = true;

      settings = {
        appLauncher = {
          backgroundOpacity = 1;
          enableClipboardHistory = true;
          pinnedExecs = [];
          position = "center";
          sortByMostUsed = true;
          useApp2Unit = false;
        };
        audio = {
          # 降低帧率节省资源
          cavaFrameRate = 39;
          mprisBlacklist = [];
          preferredPlayer = "";
          visualizerType = "linear";
          # 更精细的音量调节
          volumeStep = 5;
        };

        controlCenter = {
          avatarImage = "#e6823e";
          widgets = {
            quickSettings = [
              {id = "WiFi";}
              {id = "Bluetooth";}
              {id = "Notifications";}
              #            { id = "ScreenRecorder"; }
              {id = "PowerProfile";}
              #            { id = "WallpaperSelector"; }
              # 确保这里没有 "MediaMini" 或其他媒体相关组件
            ];
          };
        };

        bar = {
          backgroundOpacity = 1;
          density = "compact";
          floating = false;
          marginHorizontal = 0.25;
          marginVertical = 0.25;
          monitors = [];
          position = "top";
          # 是否让所有bar都有圆角背景。不需要，更极简
          showCapsule = false;
          widgets = {
            # 必须显式声明，否则默认把workspace放到center
            center = [];

            left = [
              {
                hideUnoccupied = false;
                id = "Workspace";
                labelMode = "index";
              }
            ];

            right = [
              {
                id = "SidePanelToggle";
                useDistroLogo = false;
                icon = "noctalia";
              }
              {
                id = "SystemMonitor"; # 添加系统监控
              }
              {
                id = "WiFi";
              }
              {
                id = "Bluetooth";
              }
              {
                id = "Microphone";
              }

              {
                id = "PowerProfile"; # 电源模式切换
              }

              # PLAN [2025-10-13] 目前会自动添加 fcitx 和 udiskie 这两个icon，但是无法正确展示icon，所以暂时注释，之后如果仍然需要，再处理
              #            {
              #              id = "Tray";
              #            }
              {
                hideWhenZero = true;
                id = "NotificationHistory";
                showUnreadBadge = false;
              }
              {
                alwaysShowPercentage = true;
                id = "Battery";
                warningThreshold = 30;
                checkInterval = 30; # 每30秒检查一次
                showWhenNoBattery = false; # 没有电池时隐藏组件
                displayMode = "alwaysShow";
              }
              {
                id = "Volume";
                displayMode = "alwaysShow";
              }
              {
                id = "Brightness"; # 亮度控制
                displayMode = "alwaysShow";
              }
              {
                id = "NightLight"; # 护眼模式
              }
              #            {
              #              id = "ScreenRecorder";
              #            }
              {
                formatHorizontal = "ddd MMM d HH:mm";
                formatVertical = "ddd MMM d HH:mm";
                id = "Clock";
                useMonospacedFont = true;
                usePrimaryColor = true;
              }
            ];
          };
        };
        brightness = {
          brightnessStep = 5;
        };
        colorSchemes = {
          # 为了获得类似mac的Menubar的配色
          darkMode = true;
          predefinedScheme = "Catppuccin";
          useWallpaperColors = false;
        };

        general = {
          # 直接使用我最喜欢的纯色头像，而非图片
          avatarImage = "#e6823e";

          # 开启之后，在点击任意menubar按钮后，会产生一个带有当前配色的蒙层。比如说如果当前是银白色配色，那么就会产生一个银白色的蒙层，很丑
          dimDesktop = false;
          # 禁用工具提示（hover之后会有tip）
          disableTooltips = true;
          # 关闭动画
          animationSpeed = 0;

          forceBlackScreenCorners = false;
          radiusRatio = 1;
          screenRadiusRatio = 1;
          showScreenCorners = false;
        };
        hooks = {
          darkModeChange = "";
          enabled = false;
          wallpaperChange = "";
        };
        location = {
          name = "Shanghai";
          showWeekNumberInCalendar = false;
          use12hourFormat = false;
          # 使用摄氏度
          useFahrenheit = false;
        };
        matugen = {
          enableUserTemplates = false;
          foot = false;
          fuzzel = false;
          ghostty = false;
          gtk3 = false;
          gtk4 = false;
          kitty = false;
          pywalfox = false;
          qt5 = false;
          qt6 = false;
          vesktop = false;
        };
        network = {
          bluetoothEnabled = true;
          wifiEnabled = true;
        };

        # 调节色温
        nightLight = {
          enabled = true;
          # 自动调度（基于地理位置自动计算日出日落时间）
          autoSchedule = true;
          # 强制开启
          forced = true;

          # 定时开启相关配置
          manualSunrise = "06:30";
          manualSunset = "18:30";
          dayTemp = "6500";
          nightTemp = "4000";
        };

        notifications = {
          # 减少关键通知时长
          criticalUrgencyDuration = 10;
          doNotDisturb = false;
          lastSeenTs = 1758498577000;
          location = "top_right";
          lowUrgencyDuration = 3;
          monitors = [
          ];
          # 减少普通通知时长
          normalUrgencyDuration = 5;
        };
        #      screenRecorder = {
        #        audioCodec = "opus";
        #        audioSource = "default_output";
        #        colorRange = "limited";
        #        directory = "home/${myvars.username}/Videos";
        #        frameRate = 60;
        #        quality = "very_high";
        #        showCursor = true;
        #        videoCodec = "h264";
        #        videoSource = "portal";
        #      };

        settingsVersion = 3;
        ui = {
          fontBillboard = "Inter";
          fontDefault = "Inter";
          fontFixed = "ComicShannsMono Nerd Font";
          idleInhibitorEnabled = false;
          monitorsScaling = [
          ];
        };

        # 不需要 wallpaper，所以注释掉
        #      wallpaper = {
        ##        directory = wallpaperDir;
        #        enableMultiMonitorDirectories = false;
        #        enabled = true;
        #        fillColor = "#000000";
        #        fillMode = "crop";
        #        # monitors = [
        #        #   {
        #        #     directory = wallpaperDir;
        #        #     name = "eDP-1";
        #        #     wallpaper = wallpaper;
        #        #   }
        #        #   {
        #        #     directory = wallpaperDir;
        #        #     name = "DP-2";
        #        #     wallpaper = wallpaper;
        #        #   }
        #        # ];
        #        randomEnabled = false;
        #        randomIntervalSec = 300;
        #        setWallpaperOnAllMonitors = true;
        #        transitionDuration = 1500;
        #        transitionEdgeSmoothness = {
        #        };
        #        transitionType = "random";
        #      };
      };
      # this may also be a string or a path to a JSON file,
      # but in this case must include *all* settings.
    };
  };
}
