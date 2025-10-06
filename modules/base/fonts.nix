# Shared fonts configuration for both NixOS & Darwin
# Font configuration is handled by Stylix and platform-specific configs:
# - NixOS: Stylix manages fontconfig automatically
# - Darwin: macOS handles fontconfig internally, fonts are installed via home-manager
{pkgs, ...}: {
  fonts = {
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

      # Additional fonts for better rendering
      terminus_font
      liberation_ttf
      dejavu_fonts
    ];
  };
}
