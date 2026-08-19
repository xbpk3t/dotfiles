{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.diagram;
in
{
  # host:
  #   modules.devops.diagram.enable = true;
  #
  # ⚠️ Diagram 工具整体较重：mermaid-cli ~328M（多版本 chromium）、plantuml ~387M（JDK）。
  # 不常用可关；各工具可独立 gating，这里保持整组开关。

  options.modules.devops.diagram = with lib; {
    enable = mkEnableOption "diagram tools (mermaid-cli / plantuml / pikchr / d2)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      mermaid-cli
      plantuml
      pikchr

      d2
    ];
  };
}
