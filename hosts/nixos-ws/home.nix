{...}: {
  modules.desktop = {
    gnome.enable = true;

    zed.enable = false;

    alacritty.enable = true;
    kitty.enable = false;
    ghostty.enable = false;

    firefox.enable = true;
  };

  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      hk-hdy.enable = true;
    };
  };

  modules.tui = {
    # nvf.enable = true;
  };
}
