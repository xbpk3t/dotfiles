{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      # System fonts - basic fonts for general use
      dejavu_fonts
      ibm-plex
      inter
      roboto
      symbola
      terminus_font

      # Programming fonts - optimized for code editing
      fira-code
      fira-code-symbols
      hackgen-nf-font
      jetbrains-mono
      maple-mono.NF
      roboto-mono

      # Nerd Fonts - fonts with programming ligatures and icon support
      nerd-fonts.im-writing
      nerd-fonts.blex-mono

      # Icon fonts - symbol and icon support
      font-awesome
      material-icons
      powerline-fonts

      # Gaming and special fonts
      minecraftia

      # CJK fonts - Chinese, Japanese, Korean character support
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif

      # Emoji fonts - emoji character support
      noto-fonts-emoji
      noto-fonts-monochrome-emoji

      # Base fonts - fallback font support
      noto-fonts
    ];
  };
}
