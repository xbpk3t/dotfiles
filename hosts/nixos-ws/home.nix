{...}: {
  modules.desktop = {
    nvidia.enable = true;

    niri.enable = false;
    hyprland.enable = true;

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
}
