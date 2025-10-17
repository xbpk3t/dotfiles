{...}: {
  modules.desktop = {
    # 启用 NVIDIA 支持 - 参考 RNC idols-ai 配置
    nvidia.enable = true;

    niri.enable = true;

    shell = {
      noctalia.enable = false;
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
