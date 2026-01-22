{
  pkgs,
  lib,
  inputs,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  stylix = {
    enable = lib.mkDefault true;

    autoEnable = lib.mkDefault true;
    enableReleaseChecks = false;

    # Home Manager integration settings
    #    homeManagerIntegration = {
    #      autoImport = true;
    #      followSystem = true;
    #    };

    # 使用base00作为背景色（Gruvbox的深背景）
    #    image = config.lib.stylix.pixel "base00";
    #    image = pkgs.fetchurl {
    #      url = "https://cdn.lucc.dev/wallpapers/a1.png";
    #      hash = "sha256-NJy3pGK/I0bgmjT2Irxak3AX+8n4rHcFd2eNzC6RQtg=";
    #    };

    # 暗色主题
    polarity = "dark";

    # Color scheme configuration
    # https://nix-community.github.io/stylix/configuration.html#handmade-schemes
    # https://github.com/tinted-theming/schemes
    # 注意这里不接受 base24 的theme
    # Switch to Catppuccin Mocha for a dark, pastel-friendly palette
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # Font configuration
    fonts = {
      # Monospace font for terminals and code
      monospace = {
        # package = pkgs.nerd-fonts.jetbrains-mono;
        # name = "JetBrainsMono Nerd Font Mono";

        # https://mynixos.com/nixpkgs/package/sarasa-gothic
        # https://github.com/be5invis/sarasa-gothic

        # https://linux.do/t/topic/8043/
        # https://zhuanlan.zhihu.com/p/627059922

        # 这款字体的核心优势在于“博采众长”。它深度融合了三款知名字体的优点：Noto Sans的清晰易读性、Iosevka的编程场景适配性以及思源黑体的中文显示美感。在标准缩放比例下，无论是10pt的终端显示，还是14pt的代码编辑器视图，Sarasa-Gothic都能保持字体边缘锐利、字符间距均匀，不会出现中文与英文错位、特殊符号模糊的问题——这正是很多编程字体在中文场景下的常见短板。 更值得一提的是，Sarasa Gothic并非单一字体，而是一个“字体家族”。它覆盖了文言文（CL）、简体中文（SC）、繁体中文（TC）、香港繁体（HC）、日语（J）、韩语（K）六种语言场景，同时针对不同使用场景开发了八大类优化版本，包括通用UI显示（Gothic）、界面适配（Ui）、编程专用（Mono）、 slab风格编程（MonoSlab）、终端场景（Term）、slab风格终端（TermSlab）、固定宽度（Fixed）、slab风格固定宽度（FixedSlab）。
        package = pkgs.sarasa-gothic;
        name = "Sarasa Mono SC";
      };

      # UI文本 - 使用支持中文的字体
      sansSerif = {
        # 苹果苹方作为默认 UI 字体
        package = pkgs.apple-pingfang;
        name = "PingFang SC";
      };

      # 正式文本（比如浏览器文本）- 使用支持中文的字体
      serif = {
        package = pkgs.noto-fonts-cjk-serif;
        # Noto Serif CJK 作为 fallback
        name = "Noto Serif CJK SC";
      };

      # Emoji font - using noto-fonts-color-emoji for better compatibility
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        # GUI 应用（Qt/GTK）+ 部分工具firefox, thunderbird, vscode, jetbrains.*, discord, slack, spotify
        # 按照firefox设置为13(好像这里控制不了firefox的font size)
        # zed 设置为13就太大了，所以设置为12
        applications = 12;
        # 所有 终端模拟器alacritty, kitty, wezterm, foot, contour
        terminal = 11;
        # 桌面环境 UI（面板、菜单、图标标签）plasma 面板、任务栏、菜单字体；gnome 顶部栏、概览；sway/hyprland bar
        desktop = 12;
        # 弹出菜单、通知、上下文菜单右键菜单、通知中心、rofi/dmenu、waybar 提示、文件管理器预览
        popups = 12;
      };
    };

    targets =
      {
        rofi.enable = false;
        zed.enable = false;
        # helix本身有内置theme，比stylix提供的要好很多
        helix.enable = false;

        kitty.enable = false;

        # 配置 Firefox profile names 以避免 stylix warning
        firefox.profileNames = ["default"];
      }
      // lib.optionalAttrs isLinux {
        qt = {
          enable = true;
          platform = "qtct";
        };
      };
    # 使用默认 cursor，但是改小size
    #    cursor = {
    ##      package = pkgs.bibata-cursors;
    ##      name = "Bibata-Modern-Classic";
    ##      size = 14;
    #
    #      #      package = pkgs.apple-cursor;
    #      #      name = "macOS-BigSur-White";
    #      #      size = 14;
    #    };
  };

  home.packages = with pkgs;
    [
    ]
    ++ lib.optionals isLinux [
      # https://mynixos.com/nixpkgs/package/bibata-cursors
      bibata-cursors

      # https://github.com/ful1e5/apple_cursor
      # https://mynixos.com/nixpkgs/package/apple-cursor
      apple-cursor
    ];
}
