{
  pkgs,
  config,
  lib,
  mylib,
  ...
}: let
  cfg = config.modules.desktop.zed;
  lspPackages = mylib.langs.lspPkgs pkgs;
in {
  options.modules.desktop.zed = {
    enable = lib.mkEnableOption "Enable zed (client)";
  };

  config = lib.mkIf cfg.enable {
    # Add zed to using zed-cli, otherwise "zed not found"
    home.packages = with pkgs; [zed];

    # https://mynixos.com/home-manager/options/programs.zed-editor
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ze/zed-editor/package.nix
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;

      extraPackages = lspPackages;

      # 注意这里为显式调用（因为 userSettings 期望这里是纯 attrset 的JSON，但是我们的 settings.nix 里要通过let来保证代码复用性，所以这里改为显式调用）
      userSettings = import ./settings.nix {};
      userKeymaps = import ./keymaps.nix;
      userTasks = import ./tasks.nix;
      # https://mynixos.com/home-manager/option/programs.zed-editor.themes
      # themes 是集合（这个数据结构是为了匹配），不能直接import进去
      themes = {
        "monokai" = import ./themes.nix;
      };

      # 这几项默认都是true，所以zed的所有配置天然可变。如需为mutable files，那么需要设置为false
      # mutableUserSettings = false;
      # mutableUserKeymaps = false;
      # mutableUserTasks = false;
    };

    # https://mynixos.com/nixpkgs/package/zed-discord-presence
    # https://github.com/xhyrom/zed-discord-presence
    #
    # https://mynixos.com/nixpkgs/package/zed-editor-fhs
    #
    # https://mynixos.com/nixpkgs/package/nerd-fonts.zed-mono
  };
}
