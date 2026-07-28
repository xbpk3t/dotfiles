{
  config,
  editorMeta,
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
    # editor 跟 host metadata（commonEditor.command = hx），避免 mac 写死 zed、
    # Linux/VPS headless 打不开 GUI。
    # 不设 repoPaths：多机/多目录（Desktop/dotfiles 等）不宜绑死 ~/Code/:repo。
    home.file.".config/ghui/config.json" = {
      force = true;
      text = builtins.toJSON {
        theme = "system";
        systemThemeAutoReload = true;
        showScrollbars = false;
        editorCommand = "${editorMeta.command} {{repoPath}}";
      };
    };
  };
}
