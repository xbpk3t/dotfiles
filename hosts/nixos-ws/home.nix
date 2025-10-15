{...}: {
  modules.desktop = {
    # 启用 NVIDIA 支持 - 参考 RNC idols-ai 配置
    nvidia.enable = true;

    hyprland.enable = true;
    niri.enable = false;

    shell = {
      noctalia.enable = false;
      dms.enable = true;
    };
  };

  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
    };
  };
}
