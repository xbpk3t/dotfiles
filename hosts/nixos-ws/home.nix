{...}: {
  # 启用 NVIDIA 支持 - 参考 RNC idols-ai 配置
  modules.desktop.nvidia.enable = true;

  # 启用 Hyprland 作为主要的 Wayland 合成器
  modules.desktop.hyprland.enable = true;

  # 如果你更喜欢 Niri，可以注释上面的行并取消注释下面这行
  # modules.desktop.niri.enable = true;
}
