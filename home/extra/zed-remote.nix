{
  pkgs,
  config,
  lib,
  mylib,
  ...
}: let
  cfg = config.modules.extra.zed-remote;
  lspPackages =
    mylib.langs.lspPkgs pkgs;
in {
  options.modules.extra.zed-remote = {
    enable = lib.mkEnableOption "Enable zed remote server (headless)";
  };

  config = lib.mkIf cfg.enable {
    # 仅在远端需要的LSP/工具链
    home.packages = lspPackages;

    # 提供Zed remote server的期望路径
    home.file.".zed_server" = {
      source = "${pkgs.zed-editor.remote_server}/bin";
      recursive = true;
    };
  };
}
