{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.hunk;
  tomlFormat = pkgs.formats.toml { };
in
{
  # host:
  #   modules.devops.hunk.enable = true;
  #
  # Package: inputs.llm-agents (not nixpkgs). Bump the flake input to upgrade.
  # Config path: ~/.config/hunk/config.toml
  options.modules.devops.hunk = with lib; {
    enable = mkEnableOption "hunk review-first terminal diff viewer (nix package + config.toml)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      hunk
    ];

    # 结构化 nix → TOML（同 herdr.nix）。
    # ⚠️  Nix 注释不会带入生成的 TOML；字段语义见 hunk 上游 README。
    home.file.".config/hunk/config.toml" = {
      force = true;
      source = tomlFormat.generate "hunk-config.toml" {
        # 跟终端明暗；不强制 catppuccin（herdr UI 另管）
        theme = "auto";
        mode = "auto"; # auto | split | stack
        # 明确 git（本机不再以 jj 为主）
        vcs = "git";
        watch = false;
        exclude_untracked = false;
        line_numbers = true;
        wrap_lines = false;
        menu_bar = true;
        # agent 行旁注解默认关，减少噪音
        agent_notes = false;
        transparent_background = false;
      };
    };
  };
}
