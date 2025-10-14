{...}: {
  # 启用 NVIDIA 支持 - 参考 RNC idols-ai 配置
  modules.desktop.nvidia.enable = true;

  # 启用 Niri 作为主要的 Wayland 合成器
  # 切换到 DMS + niri 组合
  # modules.desktop.hyprland.enable = true;
  modules.desktop.niri.enable = true;


  # Desktop Shell 配置
  # 使用 modules.desktop.shell 模块来管理 shell 服务
  # 注意：NixOS 和 home-manager 的配置需要保持一致
  modules.desktop.shell = {
    # Noctalia - 设置为 false 以禁用
    noctalia.enable = false;

    # DMS - QtMultimedia 依赖问题无法通过 overlay 修复，使用 fuzzel 替代
    dms.enable = false;
  };

  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
    };
  };
}
