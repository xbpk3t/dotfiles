{config, ...}: {
  # https://mynixos.com/home-manager/options/programs.wezterm
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;

    extraConfig = ''
      local wezterm = require("wezterm")
      local config = wezterm.config_builder()

      -- 设置 Lua 模块搜索路径指向配置目录
      package.path = package.path .. ";${config.xdg.configHome}/wezterm/?.lua"

      -- 加载各个模块
      require("appearance")(wezterm, config)
      require("keybings")(wezterm, config)
      require("status")(wezterm, config)
      require("tabs")(wezterm, config)

      return config
    '';
  };

  # 将 Lua 模块文件部署到配置目录
  xdg.configFile = {
    "wezterm/appearance.lua".source = ./wezterm/appearance.lua;
    "wezterm/keybings.lua".source = ./wezterm/keybings.lua;
    "wezterm/status.lua".source = ./wezterm/status.lua;
    "wezterm/tabs.lua".source = ./wezterm/tabs.lua;
  };
}
