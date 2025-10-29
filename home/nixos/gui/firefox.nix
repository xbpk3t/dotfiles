{pkgs, ...}: {
  home = {
    # Improves trackpad scrolling in FF
    sessionVariables.MOZ_USE_XINPUT2 = "1";
    # Sometimes FF launches under XWayland otherwise
    sessionVariables.MOZ_ENABLE_WAYLAND = "1";
  };

  # policy: https://mozilla.github.io/policy-templates/
  # settings: about:config
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    # Language packs
    languagePacks = [
      "zh-CN"
      "en-US"
    ];

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
            # addons.ublock-origin
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
          # 优化 Wayland 高 DPI 渲染
          "widget.wayland.high-dpi-rendering" = true;

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

          "privacy.clearOnShutdown.cookies" = false; # 关闭浏览器时清除 Cookie
          # 清除浏览历史
          "privacy.clearOnShutdown.history" = false;
          # 阻止所有第三方 Cookie
          # [2025-10-24] 可能会导致某些网站加载失败（尤其是需要第三方 Cookie 的页面）。尝试将值改为 1（仅阻止第三方跟踪 Cookie）
          "network.cookie.cookieBehavior" = 1;

          "network.http.max-connections" = 48; # 默认 24，增加到 48
          "network.http.max-persistent-connections-per-server" = 12; # 默认 6

          # 启用 HTTP/3 以提高网络性能，尤其在高延迟网络下
          "network.http.http3.enabled" = true;

          # Auto-detect proxy settings for this network
          "network.proxy.type" = 4;

          # Performance
          "browser.startup.preXulSkeletonUI" = false;
          "browser.cache.disk.capacity" = 1048576; # 1GB cache
          # 调整缓存大小以平衡性能和磁盘使用
          "browser.cache.memory.enable" = true;
          # 1GB memory cache
          # [2025-10-24] 设置为
          # Firefox 根据系统内存自动计算最大内存缓存大小。对于你的 16GB 内存机器，Firefox 会自动分配约 32MB ~ 64MB，既够用又不浪费。
          # 检测系统总物理内存
          #根据内置阶梯表设置上限：
          # > 4GB RAM → 最大 32MB 内存缓存（默认）
          #> 8GB RAM → 约 48MB
          #> 16GB+ → 约 32~64MB（动态调整）
          # 实时动态调整：
          #
          #内存充足时，缓存可接近上限。
          #内存紧张时（比如你开了 30 个 tab），自动缩减甚至清空缓存，优先保证标签页不崩溃。
          #
          #这正是你想要的：在多标签页时，后台 tab 不挂，内存不炸。
          "browser.cache.memory.capacity" = -1;

          "image.mem.decode_bytes_at_a_time" = 32768;

          # UI improvements
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.tabs.warnOnClose" = false;
          # 减小标签页宽度，方便在小屏幕上显示更多标签
          "browser.tabs.tabMinWidth" = 50; # 默认 76
          "browser.contentblocking.category" = "strict";

          # Firefox 默认会在内存压力下挂起后台标签页
          "browser.tabs.unloadOnLowMemory" = false; # 禁用低内存时卸载标签页
          "browser.tabs.min-inactive-duration-before-unload" = 600000; # 10 分钟

          # Disable telemetry
          "datareporting.healthreport.uploadEnabled" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.archive.enabled" = false;

          # PDF viewer
          "pdfjs.disabled" = false;
          "pdfjs.enabledCache.state" = true;

          # 启用 WebRender 以改善图形性能: WebRender 是 Firefox 的现代渲染引擎，能更好地利用 GPU，尤其在 Wayland 上。你的配置有 layers.acceleration，但启用 WebRender 可以进一步优化滚动和动画。
          "gfx.webrender.all" = true;
          # 进一步优化 Wayland 下的渲染
          "gfx.webrender.compositor" = true;

          # 禁用 Firefox Sync
          # 完全禁用 Sync 功能，包括：
          # - 移除 Firefox 帐户登录入口（设置中不再显示 Sync 选项）。
          # - 停止所有同步相关的网络请求和后台进程。
          # - 消除所有 Sync 相关的开销（网络流量、CPU、内存、电池等）。
          "identity.fxaccounts.enabled" = false;

          # 英文最小size
          "font.minimum-size.x-western" = 14;
          # 中文最小size
          "font.default.zh-CN" = "sans-serif";
          "font.minimum-size.zh-CN" = 14;
          "font.name.sans-serif.zh-CN" = "PingFang SC"; # 中文无衬线字体
          "font.name.serif.zh-CN" = "PingFang SC"; # 中文衬线字体

          "font.size.monospace.zh-CN" = 14;
          "font.size.variable.zh-CN" = 14;

          # Vertical Tabs
          "sidebar.verticalTabs" = true;
          "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;
        };
      };
    };

    # Enterprise policies
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;

      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";

      # 禁用 firefox 账号（类似上面 profiles/settings 里的禁用配置），但作用范围更广（可能影响其他帐户相关功能）。
      DisableFirefoxAccounts = true;

      # 启用自动更新扩展

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

      # 禁用密码保存提示（避免Firefox 每次询问是否保存密码的提示）
      # 禁用密码管理功能，阻止 Firefox 保存任何密码
      PasswordManagerEnabled = false;
      # 禁用每次登录时弹出的保存密码提示
      OfferToSaveLogins = false;

      DisableFormHistory = true; # 禁用表单历史记录
      AutofillAddressEnabled = false; # 禁用地址自动填充
      AutofillCreditCardEnabled = false; # 禁用信用卡自动填充

      NoDefaultBookmarks = false;

      # 默认禁用自动翻译
      TranslateEnabled = false;

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

      Preferences = {
        # ------------------- Tab 预览 -------------------
        # 不预览tab的缩略图和tip
        "browser.tabs.hoverPreview.enabled" = {
          Value = false;
          Status = "locked";
        };
        "browser.tabs.hoverPreview.showThumbnails" = {
          Value = false;
          Status = "locked";
        };
        "browser.ctrlTab.sortByRecentlyUsed" = {
          Value = true;
          Status = "locked";
        };

        # ------------------- 全屏行为 -------------------
        # fullscreen下不要默认autohide search bar, 否则trigger到上面时整个layout都会修改，就很突兀
        "browser.fullscreen.autohide" = {
          Value = false;
          Status = "locked";
        };

        # ------------------- UI 缩放 -------------------
        # -1 相当于 1,也就是使用默认缩放
        # 1.0略小，1.2略大，1.1刚刚好
        "layout.css.devPixelsPerPx" = {
          Value = "1.1";
          Status = "locked";
        };
        # 搭配缩放Layout使用，保证整体缩放，而非只缩放text
        # 模拟 "Zoom Text Only"（设为 false = 只文本模式）
        "browser.zoom.full" = {
          Value = false;
          Status = "locked";
        };
        # 其他相关：禁用 APZ（异步平移/缩放）以增强文本模式兼容
        # "apz.allow_zooming" = false;
        # 禁用站点特定缩放记忆（全局统一）
        # "browser.zoom.siteSpecific" = false;

        # 这两个值不支持锁定，放到这相当于没设置
        # 禁止修改缩放参数（保证防止Ctrl+ +/- 以及 Ctrl+触控板之类误操作）
        #        "zoom.minPercent" = {
        #          Value = 110;
        #          Status = "locked";
        #        };
        #        "zoom.maxPercent" = {
        #          Value = 110;
        #          Status = "locked";
        #        };

        # Ctrl+Tab 用来toggle切换
        "browser.ctrlTab.recentlyUsedOrder" = {
          Value = true;
          Status = "locked";
        };
        "browser.ctrlTab.previews" = {
          Value = false;
          Status = "locked";
        };
      };
    };
  };
}
