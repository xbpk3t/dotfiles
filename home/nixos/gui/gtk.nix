{config, ...}: {
  # If your themes for mouse cursor, icons or windows don’t load correctly,
  # try setting them with home.pointerCursor and gtk.theme,
  # which enable a bunch of compatibility options that should make the themes load in all situations.

  #  home.pointerCursor = {
  #    gtk.enable = true;
  #    x11.enable = true;
  #    package = pkgs.bibata-cursors;
  #    name = "Bibata-Modern-Ice";
  #    size = 24;
  #  };

  # DPI 设置说明：
  # - 在 Wayland 下，缩放应该由 compositor（如 niri）通过 output scale 处理
  # - Xft.dpi 是 X11 的设置，在 Wayland 下会与 compositor 的 scale 冲突
  # - 如果同时设置 Xft.dpi 和 compositor scale，会导致双重缩放或缩放不一致
  # - 因此在 Wayland 下不设置 Xft.dpi，只在 niri config.kdl 中设置 output scale
  #
  # 注释掉 DPI 设置，改为在 niri 的 config.kdl 中通过 output scale 控制
  # xresources.properties = {
  #   # dpi for Xorg's font
  #   "Xft.dpi" = 150;
  #   # or set a generic dpi
  #   "*.dpi" = 150;
  # };

  # gtk's theme settings, generate files:
  #   1. ~/.gtkrc-2.0
  #   2. ~/.config/gtk-3.0/settings.ini
  #   3. ~/.config/gtk-4.0/settings.ini
  gtk = {
    enable = true;
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  };
}
