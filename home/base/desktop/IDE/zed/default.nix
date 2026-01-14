{
  pkgs,
  config,
  lib,
  mylib,
  ...
}: let
  cfg = config.modules.desktop.zed;
  lspPackages =
    mylib.langs.lspPkgs pkgs;
in {
  options.modules.desktop.zed = {
    enable = lib.mkEnableOption "Enable zed (client)";
  };

  config = lib.mkIf cfg.enable {
    # Add zed to using zed-cli, otherwise "zed not found"
    home.packages = with pkgs; [zed];

    # https://mynixos.com/home-manager/options/programs.zed-editor
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;

      extraPackages = lspPackages;

      extensions = import ./extensions.nix;

      userSettings = import ./settings.nix;
      userKeymaps = import ./keymaps.nix;
      userTasks = import ./tasks.nix;

      # 这几项默认都是true，所以zed的所有配置天然可变。如需为mutable files，那么需要设置为false
      mutableUserSettings = false;
      mutableUserKeymaps = false;
      mutableUserTasks = false;

      # themes = import ./themes.nix;
    };
  };
}
