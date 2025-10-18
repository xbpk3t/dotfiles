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
    image = pkgs.fetchurl {
      url = "https://cdn.lucc.dev/wallpapers/a1.png";
      hash = "sha256-NJy3pGK/I0bgmjT2Irxak3AX+8n4rHcFd2eNzC6RQtg=";
    };

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
        applications = 11;
        terminal = 12;
        desktop = 10;
        popups = 11;
      };
    };

    targets = {
      qt = {
        enable = true;
        platform = "qtct";
      };
    };
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
  };

  environment.systemPackages = with pkgs; [
    # stylix image as wallpaper, swaybg is required to achieve the effect
    swaybg
  ];
}
