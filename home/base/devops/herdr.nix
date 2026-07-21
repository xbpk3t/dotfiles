{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.herdr;
  tomlFormat = pkgs.formats.toml { };
in
{
  # host:
  #   modules.devops.herdr.enable = true;
  options.modules.devops.herdr = with lib; {
    enable = mkEnableOption "Herdr agent multiplexer (nix package + config.toml)";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      herdr
    ];

    # Official path: ~/.config/herdr/config.toml
    # Structured nix → TOML (same idea as pi-agent toJSON). Comments are not preserved.
    home.file.".config/herdr/config.toml" = {
      force = true;
      source = tomlFormat.generate "herdr-config.toml" {
        onboarding = false;
        terminal = {
          shell_mode = "auto";
          new_cwd = "follow";
        };
        session = {
          resume_agents_on_restore = true;
        };
        ui = {
          sidebar_width = 22;
          sidebar_min_width = 16;
          sidebar_max_width = 36;
          prompt_new_tab_name = false;
          toast = {
            delivery = "system";
            delay_seconds = 1;
          };
        };
        experimental = {
          pane_history = false;
        };
      };
    };
  };
}
