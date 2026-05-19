{...}: {
  modules.infra = {
    nh.enable = true;
    networking.enable = true;
  };

  modules.desktop = {
    gnome.enable = true;

    zed.enable = false;

    alacritty.enable = true;
    kitty.enable = false;
    ghostty.enable = false;

    firefox.enable = true;
  };

  modules.devops.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      hk-hdy.enable = true;
    };
  };
}
