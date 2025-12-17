{...}: {
  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
    };
  };

  modules.desktop = {
    alacritty.enable = false;
    ghostty.enable = true;
  };
}
