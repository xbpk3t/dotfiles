{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.gui.zed;
in {
  options.custom.gui.zed = {
    enable = lib.mkEnableOption "Enable kitty";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [zed];

    programs.zed-editor = {
      enable = true;
      package = pkgs.zed;

      extraPackages = with pkgs; [
        nixd # https://mynixos.com/nixpkgs/package/nixd zed的nix LSP需要nixd
        nil
        rustfmt
        rust-analyzer
      ];

      extensions = import ./extensions.nix;
      themes = import ./themes.nix;
      userSettings = import ./settings.nix;
      userKeymaps = import ./keymaps.nix;
      userTasks = import ./tasks.nix;
    };
  };
}
