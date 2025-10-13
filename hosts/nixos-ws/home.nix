{...}: {
  # 启用 NVIDIA 支持 - 参考 RNC idols-ai 配置
  modules.desktop.nvidia.enable = true;

  # 启用 Niri 作为主要的 Wayland 合成器
  # 切换到 DMS + niri 组合
  # modules.desktop.hyprland.enable = true;
  modules.desktop.niri.enable = true;

  # 启用 DMS (DankMaterialShell)
  # 注意：需要与 hosts/nixos-ws/default.nix 中的 modules.desktop.shell.dms.enable 保持一致
  modules.desktop.shell.dms.enable = true;

  # 禁用 Noctalia
  modules.desktop.shell.noctalia.enable = false;

  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
    };
  };
}
