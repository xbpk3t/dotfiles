_: {
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
    };

    desktop = {
      stylix.enable = true;
      gnome.enable = true;
      firefox.enable = true;
      ghostty.enable = true;
      zed.enable = false;
    };
  };
}
