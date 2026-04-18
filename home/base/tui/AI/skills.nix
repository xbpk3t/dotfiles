{
  config,
  lib,
  inputs,
  mylib,
  ...
}: let
  cfg = config.modules.AI.skills;
  remoteCatalog = import ./skills-catalog.nix;
  activeRemoteCatalog = lib.filterAttrs (_: repo: repo.skills != []) remoteCatalog;
  remoteSources =
    lib.mapAttrs (_: repo: {
      inherit (repo) input subdir;
      filter.nameRegex = mylib.AI.mkExactNameRegex repo.skills;
    })
    activeRemoteCatalog;
  remoteEnabledSkills = lib.flatten (lib.mapAttrsToList (_: repo: repo.skills) activeRemoteCatalog);
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
      sources =
        {
          local = {
            path = ./skills;
          };
        }
        // remoteSources;

      skills = {
        # 注意这里没有 enableAll = true，因为如果整仓开启会让配置失去控制力，不利于指定需要的skills
        enableAll = ["local"];
        enable = remoteEnabledSkills;
      };
    };
  };
}
