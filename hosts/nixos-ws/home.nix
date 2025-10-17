{...}: {
  modules.desktop = {
    nvidia.enable = true;

    niri.enable = true;
  };

  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
    };
  };
}
