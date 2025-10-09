{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.custom.gui.wezterm;
in {
  options.custom.gui.wezterm = {
    enable = mkEnableOption "wezterm terminal";
  };

  config = mkIf cfg.enable {
    # https://mynixos.com/home-manager/options/programs.wezterm
    # 几乎完美的wezterm配置
    # 这里需要注意，使用stylix时，会自动配置wezterm的主配置文件 wezterm.lua，具体参考
    # https://github.com/nix-community/stylix/blob/master/modules/wezterm/hm.nix
    # 所以如果直接 xdg.configFile就会覆盖掉stylix生成的。因此要通过extraConfig来自定义配置项的集成
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;

    # Stylix 将通过 extraConfig 应用用户的自定义配置
    extraConfig = ''
      -- 加载自定义模块
      require("keybings")(wezterm, config)
      require("status")(wezterm, config)
    '';
    };

    # 将 Lua 模块文件部署到配置目录，让 Stylix 可以引用
    xdg.configFile = {
      "wezterm/keybings.lua".source = ./wezterm/keybings.lua;
      "wezterm/status.lua".source = ./wezterm/status.lua;
    };
  };
}
