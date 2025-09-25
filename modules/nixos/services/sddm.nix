# SDDM is a display manager for X11 and Wayland
{
  pkgs,
  config,
  lib,
  ...
}: let
  foreground = config.stylix.base16Scheme.base00;
  textColor = config.stylix.base16Scheme.base05;
  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "pixel_sakura";
    themeConfig =
      if lib.hasSuffix "sakura_static.png" config.stylix.image
      then {
        FormPosition = "left";
        Blur = "2.0";
      }
      else if lib.hasSuffix "studio.png" config.stylix.image
      then {
        Background = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/anotherhadi/nixy-wallpapers/refs/heads/main/wallpapers/studio.gif";
          sha256 = "sha256-qySDskjmFYt+ncslpbz0BfXiWm4hmFf5GPWF2NlTVB8=";
        };
        HeaderTextColor = "#${textColor}";
        DateTextColor = "#${textColor}";
        TimeTextColor = "#${textColor}";
        LoginFieldTextColor = "#${textColor}";
        PasswordFieldTextColor = "#${textColor}";
        UserIconColor = "#${textColor}";
        PasswordIconColor = "#${textColor}";
        WarningColor = "#${textColor}";
        LoginButtonBackgroundColor = "#${foreground}";
        SystemButtonsIconsColor = "#${foreground}";
        SessionButtonTextColor = "#${textColor}";
        VirtualKeyboardButtonTextColor = "#${textColor}";
        DropdownBackgroundColor = "#${foreground}";
        HighlightBackgroundColor = "#${textColor}";
      }
      else {
        FormPosition = "left";
        Blur = "4.0";
        Background = "${toString config.stylix.image}";
        HeaderTextColor = "#${textColor}";
        DateTextColor = "#${textColor}";
        TimeTextColor = "#${textColor}";
        LoginFieldTextColor = "#${textColor}";
        PasswordFieldTextColor = "#${textColor}";
        UserIconColor = "#${textColor}";
        PasswordIconColor = "#${textColor}";
        WarningColor = "#${textColor}";
        LoginButtonBackgroundColor = "#${config.stylix.base16Scheme.base01}";
        SystemButtonsIconsColor = "#${textColor}";
        SessionButtonTextColor = "#${textColor}";
        VirtualKeyboardButtonTextColor = "#${textColor}";
        DropdownBackgroundColor = "#${config.stylix.base16Scheme.base01}";
        HighlightBackgroundColor = "#${textColor}";
        FormBackgroundColor = "#${config.stylix.base16Scheme.base01}";
      };
  };
in {
  services.displayManager = {
    sddm = {
      package = pkgs.kdePackages.sddm;
      extraPackages = [sddm-astronaut];
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
    };
  };

  environment.systemPackages = [sddm-astronaut];
}
