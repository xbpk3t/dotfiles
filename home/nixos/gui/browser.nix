{pkgs, ...}: {
  #  programs.chromium = {
  #    enable = true;
  #    package = pkgs.chromium;
  #
  #    # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
  #    commandLineArgs = [
  #      "--ozone-platform-hint=auto"
  #      "--ozone-platform=wayland"
  #      # make it use GTK_IM_MODULE if it runs with Gtk4, so fcitx5 can work with it.
  #      # (only supported by chromium/chrome at this time, not electron)
  #      "--gtk-version=4"
  #      # make it use text-input-v1, which works for kwin 5.27 and weston
  #      "--enable-wayland-ime"
  #
  #      # Chrome 字体渲染优化 - 解决 Wayland 下字体发虚问题
  #      "--enable-font-antialiasing=1"
  #      "--disable-skia-runtime-opts" # 禁用 Skia 运行时优化，改善字体渲染
  #      "--enable-features=FontPrefs,WebUIDarkMode,UseOzonePlatform"
  #      "--disable-gpu-process-crash-limit" # 防止 GPU 进程崩溃导致的字体问题
  #
  #      # 字体渲染质量优化
  #      "--force-device-scale-factor=1" # 强制设备缩放因子，避免字体模糊
  #      "--disable-lcd-text" # 在某些情况下可以改善字体渲染
  #      "--enable-native-gpu-memory-buffers" # 改善 GPU 内存缓冲，提升渲染质量
  #
  #      # 启用硬件加速 - vulkan api (可选)
  #      # "--enable-features=Vulkan"
  #    ];
  #
  #    # Extensions (using extension IDs from Chrome Web Store)
  #    extensions = [
  #      # AdGuard AdBlocker
  #      {id = "bgnkhhnnamicmpeenaelnjfhikgbkllg";}
  #
  #      # Easy Scraper
  #      {id = "cljbfnedccphacfneigoegkiieckjndh";}
  #
  #      # Immersive Translate
  #      {id = "bpoadfkcbjbfhfodiogcnhhhpibjhbnh";}
  #
  #      # OneTab
  #      {id = "chphlpgkkbolifaimnlloiipkdnihall";}
  #
  #      # Recent Tabs
  #      {id = "ocllfmhjhfmogablefmibmjcodggknml";}
  #
  #      # Wappalyzer
  #      {id = "gppongmhjkpfnbhagpmjfkannfbllamg";}
  #
  #      # Authenticator
  #      {id = "bhghoamapcdpbohphigoooaddinpkbai";}
  #      # Vimium (vim-like navigation)
  #      #      {id = "dbepggeogbaibhgnhhndojpepiihcmeb";}
  #    ];
  #  };

  home = {
    sessionVariables.MOZ_USE_XINPUT2 = "1"; # Improves trackpad scrolling in FF
    sessionVariables.MOZ_ENABLE_WAYLAND = "1"; # Sometimes FF launches under XWayland otherwise
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    # Language packs
    languagePacks = ["zh-CN" "en-US"];

    # Firefox profiles configuration
    profiles = {
      default = {
        id = 0;
        name = "default";
        isDefault = true;

        extensions = {
          force = true;
          packages = let
            addons = pkgs.nur.repos.rycee.firefox-addons;
          in [
            # 相比chrome缺少 Easy Scraper
            # Note: Some extensions are not available in NUR, commented out:
            # - adguard-adblocker (not in NUR, using ublock-origin instead)
            # - immersive-translate (not in NUR)
            # - recent-tab-switcher (not in NUR)
            # - auth-helper (not in NUR)

            addons.onetab
            addons.wappalyzer
            addons.ublock-origin
          ];
        };

        search = {
          force = true;
          default = "google";

          order = [
            "google"
            "ddg"
          ];

          engines = {
            "bing".metaData.hidden = true;
            "amazondotcom-us".metaData.hidden = true;
          };
        };

        settings = {
          # Wayland support
          # [2025-10-15] firefox已经默认支持wayland，不再需要该参数
          # "widget.wayland-client.enabled" = true;

          # Hardware acceleration
          "layers.acceleration.force-enabled" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.gpu-process-kill-and-launch" = true;
          # 优化硬件视频解码以降低 CPU 使用。添加 media.ffmpeg.hwaccel.enabled 可以进一步支持硬件解码，尤其在视频密集页面上。
          "media.ffmpeg.hwaccel.enabled" = true;

          # Privacy and security
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.donottrackheader.enabled" = true;

          # Performance
          "browser.startup.preXulSkeletonUI" = false;
          "browser.cache.disk.capacity" = 1048576; # 1GB cache
          # 调整缓存大小以平衡性能和磁盘使用
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = 524288;

          "image.mem.decode_bytes_at_a_time" = 32768;

          # UI improvements
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.tabs.warnOnClose" = false;
          "browser.contentblocking.category" = "strict";

          # 自动把所有UI以及网页内容都缩放到90%，比较适配我的14寸laptop
          # hyprland和niri对该配置的处理不同，hyprland下90%的布局、字号正好，但是niri下就太小了，所以恢复为默认
          "layout.css.devPixelsPerPx" = 1;

          # Disable telemetry
          "datareporting.healthreport.uploadEnabled" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.archive.enabled" = false;

          # PDF viewer
          "pdfjs.disabled" = false;
          "pdfjs.enabledCache.state" = true;

          # 启用 WebRender 以改善图形性能: WebRender 是 Firefox 的现代渲染引擎，能更好地利用 GPU，尤其在 Wayland 上。你的配置有 layers.acceleration，但启用 WebRender 可以进一步优化滚动和动画。
          "gfx.webrender.all" = true;
        };
      };
    };

    # Enterprise policies
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableScreenshots = false;
      DisableFormHistory = false;
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";

      # 启用自动更新扩展
      ExtensionsUpdate = true;

      EnableTrackingProtection = {
        Value = true;
        Locked = false;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };
      EncryptedMediaExtensions = {
        Enabled = true;
        Locked = false;
      };
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        SponsoredPocket = false;
        Snippets = false;
        Locked = false;
      };
      PasswordManagerEnabled = true;
      NoDefaultBookmarks = false;
      OfferToSaveLogins = true;
      SanitizeOnShutdown = {
        Cache = false;
        Cookies = false;
        Downloads = false;
        FormData = false;
        History = false;
        Sessions = false;
        SiteSettings = false;
        OfflineApps = false;
        LockPreferences = false;
      };
    };
  };
}
