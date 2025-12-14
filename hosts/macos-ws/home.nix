{...}: {
  # 系统级配置启用
  # modules.networking.singbox.enable = true;
  modules = {
    ssh = {
      enable = true;
      hosts = {
        github.enable = true;
        vps.enable = true;
      };
    };
    desktop = {
    };
  };
}
