_: {
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
    };

    desktop = {
      stylix.enable = true;

      gnome.enable = true;

      zed.enable = false;

      ghostty.enable = false;

      firefox.enable = true;
    };

    devops.ssh = {
      enable = true;
      hosts = {
        github.enable = true;
        hk-hdy.enable = true;
      };
    };
  };
}
