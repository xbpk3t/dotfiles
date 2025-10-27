{
  pkgs,
  lib,
  ...
}: {
  stylix = {
    enable = lib.mkDefault true;

    autoEnable = lib.mkDefault true;

    # Home Manager integration settings
    homeManagerIntegration = {
      autoImport = true;
      followSystem = true;
    };

    # 使用base00作为背景色（Gruvbox的深背景）
    #    image = config.lib.stylix.pixel "base00";
    #    image = pkgs.fetchurl {
    #      url = "https://cdn.lucc.dev/wallpapers/a1.png";
    #      hash = "sha256-NJy3pGK/I0bgmjT2Irxak3AX+8n4rHcFd2eNzC6RQtg=";
    #    };

    # 暗色主题
    polarity = "dark";

    # Color scheme configuration
    # Using Gruvbox Dark Hard - a popular terminal-friendly theme
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    # Font configuration
    fonts = {
      # Monospace font for terminals and code
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };

      # UI文本 - 使用支持中文的字体
      sansSerif = {
        package = pkgs.noto-fonts-cjk-sans;
        # Noto Sans CJK 作为 fallback
        name = "Noto Sans CJK SC";
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

    targets = {
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

  environment.systemPackages = with pkgs; [
    # stylix image as wallpaper, swaybg is required to achieve the effect
    # swaybg

    # https://mynixos.com/nixpkgs/package/bibata-cursors
    bibata-cursors

    # https://github.com/ful1e5/apple_cursor
    # https://mynixos.com/nixpkgs/package/apple-cursor
    apple-cursor
  ];
}
