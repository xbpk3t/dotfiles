{...}: {
  modules.desktop = {
    nvidia.enable = true;

    niri.enable = true;

    zed.enable = false;
  };

  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
    };
  };
}
