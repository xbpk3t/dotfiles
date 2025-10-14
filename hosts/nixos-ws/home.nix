{...}: {
  # 启用 NVIDIA 支持 - 参考 RNC idols-ai 配置
  modules.desktop.nvidia.enable = true;

  # 启用 Niri 作为主要的 Wayland 合成器
  modules.desktop.niri.enable = true;

  modules.desktop.shell = {
    noctalia.enable = true;
    DMS.enable = false;
  };

  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
    };
  };
}
