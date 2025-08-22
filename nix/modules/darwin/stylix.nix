# Stylix configuration for system-wide theming
# https://github.com/danth/stylix
{ pkgs, ... }:

{
  stylix = {
    enable = true;

    # Disable auto-enable to avoid conflicts with existing configurations
    autoEnable = false;

    # Base16 color scheme
    # You can find more schemes at: https://github.com/tinted-theming/base16-schemes
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";

    # Wallpaper (optional)
    # image = ./wallpaper.jpg;

    # Polarity (dark or light)
    polarity = "dark";

    # Cursor configuration
#    cursor = {
#      package = pkgs.bibata-cursors;
#      name = "Bibata-Modern-Classic";
#      size = 24;
#    };

    # Font configuration

    # Opacity settings
    opacity = {
      applications = 1.0;
      terminal = 0.9;
      desktop = 1.0;
      popups = 1.0;
    };

    # Target applications are disabled by autoEnable = false
    # You can manually enable specific targets if needed:
    # targets.alacritty.enable = true;
    # targets.kitty.enable = true;
    # etc.
  };

  # Additional packages for theming support
  environment.systemPackages = with pkgs; [
    # Color scheme tools
    base16-schemes
  ];

  # Home Manager integration for user-specific theming
  # This will be automatically applied to applications configured through home-manager
}
