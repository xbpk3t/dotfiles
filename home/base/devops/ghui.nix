{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.ghui;
in
{
  # host:
  #   modules.devops.ghui.enable = true;
  #
  # Package: nixpkgs pkgs.ghui（mynixos 同源）。
  # Config path: ~/.config/ghui/config.json
  # 依赖本机已配置的 `gh` auth（programs.gh + GITHUB_TOKEN）。
  options.modules.devops.ghui = with lib; {
    enable = mkEnableOption "ghui GitHub PR TUI (nixpkgs package + config.json)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.ghui ];

    # 结构化 nix → JSON（同 pi-agent settings 思路）。
    # workspace 默认 editorCommand 是 nvim；本机 GUI 主编辑为 Zed。
    # 不设 repoPaths：多机/多目录（Desktop/dotfiles 等）不宜绑死 ~/Code/:repo。
    home.file.".config/ghui/config.json" = {
      force = true;
      text = builtins.toJSON {
        theme = "system";
        systemThemeAutoReload = true;
        showScrollbars = false;
        editorCommand = "zed {{repoPath}}";
      };
    };
  };
}
