{pkgs, ...}: {
  programs.chromium = {
      enable = true;
      package = pkgs.chromium;

      # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
      commandLineArgs = [
        "--ozone-platform-hint=auto"
        "--ozone-platform=wayland"
        # make it use GTK_IM_MODULE if it runs with Gtk4, so fcitx5 can work with it.
        # (only supported by chromium/chrome at this time, not electron)
        "--gtk-version=4"
        # make it use text-input-v1, which works for kwin 5.27 and weston
        "--enable-wayland-ime"

        # Chrome 字体渲染优化 - 解决 Wayland 下字体发虚问题
        "--enable-font-antialiasing=1"
        "--disable-skia-runtime-opts" # 禁用 Skia 运行时优化，改善字体渲染
        "--enable-features=FontPrefs,WebUIDarkMode,UseOzonePlatform"
        "--disable-gpu-process-crash-limit" # 防止 GPU 进程崩溃导致的字体问题

        # 字体渲染质量优化
        "--force-device-scale-factor=1" # 强制设备缩放因子，避免字体模糊
        "--disable-lcd-text" # 在某些情况下可以改善字体渲染
        "--enable-native-gpu-memory-buffers" # 改善 GPU 内存缓冲，提升渲染质量

        # 启用硬件加速 - vulkan api (可选)
        # "--enable-features=Vulkan"
      ];

      # Extensions (using extension IDs from Chrome Web Store)
      extensions = [
        # AdGuard AdBlocker
        {id = "bgnkhhnnamicmpeenaelnjfhikgbkllg";}

        # Easy Scraper
        {id = "cljbfnedccphacfneigoegkiieckjndh";}

        # Immersive Translate
        {id = "bpoadfkcbjbfhfodiogcnhhhpibjhbnh";}

        # OneTab
        {id = "chphlpgkkbolifaimnlloiipkdnihall";}

        # Recent Tabs
        {id = "ocllfmhjhfmogablefmibmjcodggknml";}

        # Wappalyzer
        {id = "gppongmhjkpfnbhagpmjfkannfbllamg";}

        # Authenticator
        {id = "bhghoamapcdpbohphigoooaddinpkbai";}

        # Vimium (vim-like navigation)
        {id = "dbepggeogbaibhgnhhndojpepiihcmeb";}
      ];
    };

    #    firefox = {
    #      enable = false;
    #      package = pkgs.firefox;
    #
    #      # Language packs
    #      languagePacks = ["zh-CN" "en-US"];
    #
    #      # Firefox profiles configuration
    #      profiles = {
    #        default = {
    #          id = 0;
    #          name = "default";
    #          isDefault = true;
    #
    #          settings = {
    #            # Wayland support
    #            "widget.wayland-client.enabled" = true;
    #
    #            # Font rendering optimization
    #            "gfx.font_rendering.cleartype_params.cambria" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.consolas" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.ebrima" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.georgia" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.latin" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.malgun_gothic" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.microsoft_jhenghei" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.microsoft_yahei" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.segoe_ui" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.tahoma" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.times_new_roman" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.trebuchet_ms" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.verdana" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #            "gfx.font_rendering.cleartype_params.vertical_stems" = "1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    #
    #            # Hardware acceleration
    #            "layers.acceleration.force-enabled" = true;
    #            "media.ffmpeg.vaapi.enabled" = true;
    #            "media.gpu-process-kill-and-launch" = true;
    #
    #            # Privacy and security
    #            "privacy.trackingprotection.enabled" = true;
    #            "privacy.trackingprotection.socialtracking.enabled" = true;
    #            "privacy.donottrackheader.enabled" = true;
    #
    #            # Performance
    #            "browser.startup.preXulSkeletonUI" = false;
    #            "browser.cache.disk.capacity" = 1048576; # 1GB cache
    #            "image.mem.decode_bytes_at_a_time" = 32768;
    #
    #            # UI improvements
    #            "browser.toolbars.bookmarks.visibility" = "never";
    #            "browser.tabs.warnOnClose" = false;
    #            "browser.contentblocking.category" = "strict";
    #
    #            # Disable telemetry
    #            "datareporting.healthreport.uploadEnabled" = false;
    #            "toolkit.telemetry.enabled" = false;
    #            "toolkit.telemetry.archive.enabled" = false;
    #
    #            # PDF viewer
    #            "pdfjs.disabled" = false;
    #            "pdfjs.enabledCache.state" = true;
    #          };
    #        };
    #      };
    #
    #      # Enterprise policies
    #      policies = {
    #        DisableTelemetry = true;
    #        DisableFirefoxStudies = true;
    #        DisablePocket = true;
    #        DisableScreenshots = false;
    #        DisableFormHistory = false;
    #        DontCheckDefaultBrowser = true;
    #        DisplayBookmarksToolbar = "never";
    #        DisplayMenuBar = "default-off";
    #        EnableTrackingProtection = {
    #          Value = true;
    #          Locked = false;
    #          Cryptomining = true;
    #          Fingerprinting = true;
    #          EmailTracking = true;
    #        };
    #        EncryptedMediaExtensions = {
    #          Enabled = true;
    #          Locked = false;
    #        };
    #        FirefoxHome = {
    #          Search = true;
    #          TopSites = false;
    #          SponsoredTopSites = false;
    #          Highlights = false;
    #          Pocket = false;
    #          SponsoredPocket = false;
    #          Snippets = false;
    #          Locked = false;
    #        };
    #        PasswordManagerEnabled = true;
    #        NoDefaultBookmarks = false;
    #        OfferToSaveLogins = true;
    #        SanitizeOnShutdown = {
    #          Cache = false;
    #          Cookies = false;
    #          Downloads = false;
    #          FormData = false;
    #          History = false;
    #          Sessions = false;
    #          SiteSettings = false;
    #          OfflineApps = false;
    #          LockPreferences = false;
    #        };
    #      };
    #
    #      # Native messaging hosts (for password managers etc.)
    #      nativeMessagingHosts = with pkgs; [
    #        firefox
    #      ];
    #    };
}
