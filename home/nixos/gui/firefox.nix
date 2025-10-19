{pkgs, ...}: {
  home = {
    # Improves trackpad scrolling in FF
    sessionVariables.MOZ_USE_XINPUT2 = "1";
    # Sometimes FF launches under XWayland otherwise
    sessionVariables.MOZ_ENABLE_WAYLAND = "1";
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

          # 禁用 Firefox Sync
          # 完全禁用 Sync 功能，包括：
          # - 移除 Firefox 帐户登录入口（设置中不再显示 Sync 选项）。
          # - 停止所有同步相关的网络请求和后台进程。
          # - 消除所有 Sync 相关的开销（网络流量、CPU、内存、电池等）。
          "identity.fxaccounts.enabled" = false;
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

      # 禁用 firefox 账号（类似上面 profiles/settings 里的禁用配置），但作用范围更广（可能影响其他帐户相关功能）。
      DisableFirefoxAccounts = true;

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
