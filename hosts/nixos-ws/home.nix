{...}: {
  modules.desktop = {
    nvidia.enable = true;

    niri.enable = true;

    zed.enable = false;

    kitty.enable = true;
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
