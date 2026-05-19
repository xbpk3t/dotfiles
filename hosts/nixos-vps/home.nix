{...}: {
  modules.infra = {
    nh.enable = true;
    networking.enable = true;
  };

  modules.extra = {
    zed-remote.enable = true;
  };
}
