{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modules.AI.skills;
in
{
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

    # APM 全局 skill manifest — 声明式管理，Nix 负责放置，APM 负责安装
    home.file.".apm/apm.yml" = {
      source = ./apm.yml;
      force = true;
    };

    # 全局 APM instructions — APM includes:auto 自动发现并编译到 CLAUDE.md
    # 新增 instruction 只需往 global-instructions/ 目录丢 .md 文件即可
    home.file.".apm/instructions" = {
      source = ./global-instructions;
      recursive = true;
      force = true;
    };
  };
}
