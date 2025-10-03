{pkgs, ...}: {
  programs = {
    # source code: https://github.com/nix-community/home-manager/blob/master/modules/programs/chromium.nix
    google-chrome = {
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
  };
}
