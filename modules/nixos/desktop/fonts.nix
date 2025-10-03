{pkgs, ...}: {
  # all fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
  fonts = {
    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;
    fontDir.enable = true;

    # Import shared fonts from modules/base/fonts.nix
    packages = with pkgs; [
      # The actual font packages are now in modules/base/fonts.nix
      # This will be imported at the system level
    ];

    fontconfig = {
      # User defined default fonts
      # https://catcat.cc/post/2021-03-07/
      defaultFonts = {
        serif = [
          # 西文: 衬线字体（笔画末端有修饰(衬线)的字体，通常用于印刷。）
          "Source Serif 4"
          # 中文: 宋体（港台称明體）
          "Source Han Serif SC" # 思源宋体
          "Source Han Serif TC"
        ];
        # SansSerif 也简写做 Sans, Sans 在法语中就是「without」或者「无」的意思
        sansSerif = [
          # 西文: 无衬线字体（指笔画末端没有修饰(衬线)的字体，通常用于屏幕显示）
          "Source Sans 3"
          # 中文: 黑体
          "LXGW WenKai Screen" # 霞鹜文楷 屏幕阅读版
          "Source Han Sans SC" # 思源黑体
          "Source Han Sans TC"
        ];
        # 等宽字体
        monospace = [
          # 中文
          "Maple Mono NF CN" # 中英文宽度完美 2:1 的字体
          "Source Han Mono SC" # 思源等宽
          "Source Han Mono TC"
          # 西文
          "JetBrains Mono"
        ];
        emoji = ["Noto Color Emoji"];
      };

      # Chrome/Wayland 字体优化设置
      antialias = true; # 抗锯齿 - 必须启用以减少字体发虚

      hinting = {
        enable = true; # 启用字体微调 - 对 Chrome 发虚问题很重要
        style = "slight"; # "slight" 更适合 Wayland 和 Chrome，减少发虚
        # 可选值: "none", "slight", "medium", "full"
        # "slight" 在高分辨率屏幕上提供最佳平衡
      };

      subpixel = {
        rgba = "rgb"; # IPS 屏幕使用 rgb 排列
        lcdfilter = "default"; # LCD 滤镜，改善子像素渲染
      };

      # 针对特定字体的优化
      localConf = ''
        <?xml version='1.0'?>
        <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
        <fontconfig>
          <!-- Chrome/Chromium Wayland 字体优化 -->
          <!-- 改善中文字体渲染 -->
          <match target="font">
            <test name="family">
              <string>Source Han Sans SC</string>
              <string>Source Han Sans TC</string>
              <string>LXGW WenKai Screen</string>
            </test>
            <edit name="hintstyle" mode="assign">
              <const>hintslight</const>
            </edit>
            <edit name="antialias" mode="assign">
              <bool>true</bool>
            </edit>
            <edit name="rgba" mode="assign">
              <const>rgb</const>
            </edit>
          </match>

          <!-- 改善英文字体渲染 -->
          <match target="font">
            <test name="family">
              <string>Source Sans 3</string>
              <string>Source Serif 4</string>
              <string>JetBrains Mono</string>
            </test>
            <edit name="hintstyle" mode="assign">
              <const>hintslight</const>
            </edit>
            <edit name="antialias" mode="assign">
              <bool>true</bool>
            </edit>
          </match>

          <!-- 防止字体位图化 - 对 Chrome 很重要 -->
          <match target="font">
            <test name="pixelsize" compare="less_eq">
              <double>16</double>
            </test>
            <edit name="embeddedbitmap" mode="assign">
              <bool>false</bool>
            </edit>
          </match>

          <!-- 改善小字体渲染 -->
          <match target="font">
            <test name="pixelsize" compare="less">
              <double>10</double>
            </test>
            <edit name="autohint" mode="assign">
              <bool>true</bool>
            </edit>
          </match>
        </fontconfig>
      '';
    };
  };

  # https://wiki.archlinux.org/title/KMSCON
  services.kmscon = {
    # Use kmscon as the virtual console instead of gettys.
    # kmscon is a kms/dri-based userspace virtual terminal implementation.
    # It supports a richer feature set than the standard linux console VT,
    # including full unicode support, and when the video card supports drm should be much faster.
    enable = true;
    fonts = with pkgs; [
      {
        name = "Maple Mono NF CN";
        package = maple-mono.NF-CN-unhinted;
      }
      {
        name = "JetBrainsMono Nerd Font";
        package = nerd-fonts.jetbrains-mono;
      }
    ];
    extraOptions = "--term xterm-256color";
    extraConfig = "font-size=14";
    # Whether to use 3D hardware acceleration to render the console.
    hwRender = true;
  };
}
