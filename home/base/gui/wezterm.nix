{config, ...}: {
  # https://mynixos.com/home-manager/options/programs.wezterm
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };

  # 将 Lua 模块文件部署到配置目录
  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./wezterm/wezterm.lua;
    "wezterm/appearance.lua".source = ./wezterm/appearance.lua;
    "wezterm/keybings.lua".source = ./wezterm/keybings.lua;
    "wezterm/status.lua".source = ./wezterm/status.lua;
    "wezterm/tabs.lua".source = ./wezterm/tabs.lua;
  };
}
