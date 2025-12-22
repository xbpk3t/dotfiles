{
  pkgs,
  config,
  lib,
  ...
}
: let
  cfg = config.modules.desktop.goland;
in {
  options.modules.desktop.goland = with lib; {
    enable = mkEnableOption "Goland Enable";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      jetbrains.goland
    ];

    home.sessionVariables = {
      # JetBrains IDE（含 GoLand）启用 Wayland 渲染；新版本默认支持，老版本需此开关
      "JBR_ENABLE_WAYLAND" = "1";
    };
  };
}
