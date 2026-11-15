_: {
  modules = {
    infra = {
      basePackages.enable = true;
      nh.enable = true;
      networking.enable = true;
    };

    kernel = {
      basePackages.enable = true;
      gpg.enable = true;
      network.enable = true;
      ssh.enable = true;
    };

    devops.helix.enable = true;

    desktop = {
      stylix.enable = true;
      gnome.enable = true;
      firefox.enable = false;
      ghostty.enable = false;
      zed.enable = false;
    };

    xdg.enable = true;
  };
}
