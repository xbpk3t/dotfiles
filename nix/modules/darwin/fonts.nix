# Darwin fonts configuration
# Font management and configuration for macOS
{pkgs, ...}: {
  # Fonts configuration
  fonts = {
    # Install fonts (renamed from fonts.fonts to fonts.packages)
    packages = with pkgs; [
      # Programming fonts
      jetbrains-mono
      # fira-code
      # cascadia-code
      # source-code-pro

      # Nerd fonts
      nerd-fonts.jetbrains-mono

      # Emoji fonts
      noto-fonts-color-emoji
      # material-design-icons

      # Chinese font
      # wqy_zenhei
    ];

    # Note: Font configuration on macOS is handled by the system
    # fontconfig is not available on nix-darwin, font rendering is managed by macOS
  };
}
