# Shared fonts configuration for both NixOS & Darwin
{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      # Serif fonts (衬线字体 - 用于印刷)
      source-serif-pro
      # source-han-serif-sc # 思源宋体简体中文
      # source-han-serif-tc # 思源宋体繁体中文

      # Sans-serif fonts (无衬线字体 - 用于屏幕显示)
      source-sans-pro
      # source-han-sans-sc # 思源黑体简体中文
      # source-han-sans-tc # 思源黑体繁体中文
      lxgw-wenkai-screen # 霞鹜文楷屏幕阅读版

      # Monospace fonts (等宽字体)
      jetbrains-mono
      # source-han-mono-sc # 思源等宽简体中文
      # source-han-mono-tc # 思源等宽繁体中文
      # maple-mono-sc # Maple Mono SC (中英文宽度完美 2:1 的字体)
      # maple-mono-nf # Maple Mono NF (包含 Nerd Font 图标)

      # Nerd fonts for terminal and programming
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      # nerd-fonts.source-code-pro

      # Emoji fonts
      noto-fonts-color-emoji
      noto-fonts-emoji

      # Additional fonts for better rendering
      terminus_font
      liberation_ttf
      dejavu_fonts
    ];

    # Font configuration is handled by platform-specific configs:
    # - NixOS: modules/nixos/desktop/fonts.nix (includes fontconfig settings)
    # - Darwin: modules/darwin/fonts.nix (macOS handles fontconfig internally)
  };
}
