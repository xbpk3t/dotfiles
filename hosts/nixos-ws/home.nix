{...}: {
  modules.desktop = {
    nvidia.enable = true;
    gnome.enable = true;

    zed.enable = false;

    kitty.enable = false;
    ghostty.enable = false;
  };

  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
    };
  };

  modules.tui = {
    nvf.enable = true;
  };

  modules.networking = {
    netbird.enable = true;
  };
}
