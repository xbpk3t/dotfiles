# https://mynixos.com/nixpkgs/options/fonts.fontconfig
# 注意：本文件仅作为stylix的补充配置
{pkgs, ...}: {
  # 修复 Chromium/Electron 应用字体模糊问题
  # 启用 stem darkening 以改善小字体在深色背景下的渲染
  # 参考: https://blog.aktsbot.in/no-more-blurry-fonts.html
  environment.sessionVariables = {
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };

  # all fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
  fonts = {
    # use fonts specified by user rather than default ones
    # Stylix 已处理
    enableDefaultPackages = false;
    fontDir.enable = true;

    packages = with pkgs; [
      source-serif-pro
      source-sans-pro

      # https://mynixos.com/nixpkgs/package/inter-nerdfont
      inter-nerdfont

      # Monospace fonts (等宽字体)
      jetbrains-mono

      # Nerd fonts for terminal and programming
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code

      # Emoji fonts
      noto-fonts-color-emoji
      noto-fonts-emoji

      # Chinese fonts for CJK support
      noto-fonts-cjk-sans # 思源黑体
      noto-fonts-cjk-serif # 思源宋体
      source-han-sans # Adobe 思源黑体
      lxgw-neoxihei # https://github.com/lxgw/LxgwNeoXiHei 霞鹜新晰
      wqy_zenhei # 文泉驿正黑 https://mynixos.com/nixpkgs/package/wqy_zenhei
      wqy_microhei # https://mynixos.com/nixpkgs/package/wqy_microhei

      # Additional fonts for better rendering
      terminus_font
      liberation_ttf
      dejavu_fonts
    ];

    fontconfig = {
      # User defined default fonts
      # https://catcat.cc/post/2021-03-07/
      # 这部分stylix已经处理了，所以注释掉
      # [2025-10-20] 确实需要 fontconfig 来做 font的fallback处理。因为如果只配置stylix的font，无法适配很多网站的font，就很丑。
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
      # 抗锯齿 - 必须启用以减少字体发虚
      antialias = true;

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
    };
  };
}
