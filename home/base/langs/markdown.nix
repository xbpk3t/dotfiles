{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.langs.markdown;
in
{
  options.modules.langs.markdown.enable =
    lib.mkEnableOption "Markdown tools (mdq / markdownlint-cli)";

  config.home = lib.mkIf cfg.enable {
    packages = with pkgs; [
      # python313Packages.markitdown
      # docling
      mdq

      markdownlint-cli
      # doxx
    ];
  };
}
