{pkgs, ...}: {
  stylix = {
    # Enable Stylix theming
    enable = true;
    autoEnable = true;

    # Target-specific configurations
    # Enable theming for supported applications
    # Note: Using autoEnable instead of specific targets for compatibility
    # stylix.targets = {
    #   # Specific targets may not be available in current stylix version
    #   # Let autoEnable handle the configuration automatically
    # };

    # image = "../../wallpapers/beautifulmountainscape.jpg";
    polarity = "dark";

    targets = {
      #      waybar.enable = false;
      #      rofi.enable = false;
      #      hyprland.enable = false;
      #      hyprlock.enable = false;
      qt = {
        enable = true;
        platform = "qtct";
      };
    };

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

      # Sans-serif font for UI elements
      sansSerif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };

      # Serif font (optional)
      serif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };

      # Emoji font - using noto-fonts-color-emoji for better compatibility
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };

    # Font sizes
    fonts.sizes = {
      #      applications = 12;
      #      terminal = 14;
      #      desktop = 12;
      #      popups = 12;

      applications = 10;
      terminal = 12;
      desktop = 9;
      popups = 10;
    };

    # Home Manager integration settings
    homeManagerIntegration = {
      autoImport = true;
      followSystem = true;
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
  };

  # Override specific settings if needed
  # For example, make some applications have transparent backgrounds
  #  stylix.targets.neovim = {
  #    transparentBackground = {
  #      main = true;
  #      signColumn = true;
  #      numberLine = true;
  #    };
  #  };

  # Custom color overrides (optional)
  # Uncomment and modify if you want to override specific colors
  # stylix.override = {
  #   base00 = "#1d2021";  # background
  #   base01 = "#3c3836";  # lighter background
  #   base02 = "#504945";  # selection background
  #   base03 = "#665c54";  # comments
  #   base04 = "#bdae93";  # dark foreground
  #   base05 = "#d5c4a1";  # foreground
  #   base06 = "#ebdbb2";  # light foreground
  #   base07 = "#fbf1c7";  # light background
  #   base08 = "#fb4934";  # red
  #   base09 = "#fe8019";  # orange
  #   base0A = "#fabd2f";  # yellow
  #   base0B = "#b8bb26";  # green
  #   base0C = "#8ec07c";  # cyan
  #   base0D = "#83a598";  # blue
  #   base0E = "#d3869b";  # purple
  #   base0F = "#d65d0e";  # brown
  # };

  # Optional: Enable base16 shell integration for terminals
  # This will set environment variables for the current color scheme
  # Note: This target may not exist in your current Stylix version
  # stylix.targets.console.enable = true;
}
