{
  pkgs,
  config,
  lib,
  ...
}
: let
  cfg = config.modules.desktop.jetbrains-remote;
  packages = with pkgs.jetbrains; [
    # jetbrains.goland
    # https://mynixos.com/nixpkgs/package/jetbrains.goland
    goland
    # https://mynixos.com/nixpkgs/package/jetbrains.jdk-no-jcef
    jdk
  ];
in {
  options.modules.desktop.jetbrains-remote = with lib; {
    enable = mkEnableOption "Jetbrains IDE Remote Development Enable";
  };

  config = lib.mkIf cfg.enable {
    # https://mynixos.com/nixpkgs/package/jetbrains.gateway

    home.packages = packages;

    # https://mynixos.com/home-manager/options/programs.jetbrains-remote
    programs.jetbrains-remote = {
      enable = true;
      ides = packages;
    };

    home.sessionVariables = {
      # JetBrains IDE（含 GoLand）启用 Wayland 渲染；新版本默认支持，老版本需此开关
      "JBR_ENABLE_WAYLAND" = "1";
    };
  };
}
