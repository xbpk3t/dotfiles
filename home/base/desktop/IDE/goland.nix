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
  };
}
