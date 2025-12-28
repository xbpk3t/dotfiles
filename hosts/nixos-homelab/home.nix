{...}: {
  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
      hk.enable = true;
    };
  };
}
