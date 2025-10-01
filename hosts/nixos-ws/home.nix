{...}: {
  # 启用 NVIDIA 支持 - 参考 RNC idols-ai 配置
  modules.desktop.nvidia.enable = true;

  # 启用 Hyprland 作为主要的 Wayland 合成器
  modules.desktop.hyprland.enable = true;
  # modules.desktop.niri.enable = true;
}
