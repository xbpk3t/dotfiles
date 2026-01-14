{
  config,
  lib,
  mylib,
  pkgs,
  ...
}: let
  cfg = config.modules.langs.lsp;
in {
  options.modules.langs.lsp = with lib; {
    enable = mkEnableOption "Enable common LSP/toolchain packages";

    packages = mkOption {
      type = types.listOf types.package;
      default = mylib.langs.lspPkgs pkgs;
      description = "Common LSP/toolchain packages shared by IDEs.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = cfg.packages;
  };
}
