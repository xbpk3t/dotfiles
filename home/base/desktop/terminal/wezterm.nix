{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.desktop.wezterm;
in {
  options.modules.desktop.wezterm = {
    enable = mkEnableOption "wezterm terminal";
  };

  config = mkIf cfg.enable {
    # https://mynixos.com/home-manager/options/programs.wezterm
    #
    # https://mynixos.com/nixpkgs/package/wezterm
    #
    # https://github.com/wezterm/wezterm
    #
    #
    # 几乎完美的wezterm配置
    # 这里需要注意，使用stylix时，会自动配置wezterm的主配置文件 wezterm.lua，具体参考
    # https://github.com/nix-community/stylix/blob/master/modules/wezterm/hm.nix
    # 所以如果直接 xdg.configFile就会覆盖掉stylix生成的。因此要通过extraConfig来自定义配置项的集成
    #
    #
    # 如果在 stylix 配置 wezterm = false，
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;

      # Stylix 将通过 extraConfig 应用用户的自定义配置
      extraConfig = builtins.readFile ./wezterm.lua;
    };
  };
}
