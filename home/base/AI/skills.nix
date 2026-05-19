{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.modules.AI.skills;
in {
  imports = [
    inputs.agent-skills.homeManagerModules.default
  ];

  options.modules.AI.skills = with lib; {
    enable = mkEnableOption "Enable shared agent skills";
  };

  config = lib.mkIf cfg.enable {
    programs.agent-skills = {
      enable = true;
      sources = {
        local = {
          path = ./skills;
        };
      };

      skills = {
        # enableAll = [ "local" ];
        enableAll = true;
      };
    };
  };
}
