{
  pkgs,
  lib,
  config,
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
    image = config.lib.stylix.pixel "base00";

    polarity = "dark";

    # Color scheme configuration
    # Using Gruvbox Dark Hard - a popular terminal-friendly theme
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    targets = {
      qt = {
        enable = true;
        platform = "qtct";
      };
    };

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

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
  };

  # PLAN  [2025-10-06] 需要根据实际需求调整配色，当前为Gruvbox 默认值，所以注释掉
  # Custom color overrides (optional)
  # Uncomment and modify if you want to override specific colors
  #  stylix.override = {
  #    base00 = "#1d2021"; # background
  #    base01 = "#3c3836"; # lighter background
  #    base02 = "#504945"; # selection background
  #    base03 = "#665c54"; # comments
  #    base04 = "#bdae93"; # dark foreground
  #    base05 = "#d5c4a1"; # foreground
  #    base06 = "#ebdbb2"; # light foreground
  #    base07 = "#fbf1c7"; # light background
  #    base08 = "#fb4934"; # red
  #    base09 = "#fe8019"; # orange
  #    base0A = "#fabd2f"; # yellow
  #    base0B = "#b8bb26"; # green
  #    base0C = "#8ec07c"; # cyan
  #    base0D = "#83a598"; # blue
  #    base0E = "#d3869b"; # purple
  #    base0F = "#d65d0e"; # brown
  #  };
}
