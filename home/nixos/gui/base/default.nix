{...}: {
  imports = [
    ./desktop
    ./fcitx5
    ./gtk.nix
    ./media.nix
    ./misc.nix
    ./wayland-apps.nix
    ./xdg.nix
    # ./wallpaper  # Temporarily disabled due to missing wallpapers parameter
  ];
}
