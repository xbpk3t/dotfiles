{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.AI.skills;
in
{
  options.modules.AI.skills = with lib; {
    enable = mkEnableOption "Enable shared agent skills";
  };

  config = lib.mkIf cfg.enable {
    # 本地 skills 直接 symlink，远程 skills 由 APM 管理
    home.file = {

      ".local/share/skills".source = ./skills;
      # APM 全局 skill manifest — 声明式管理，Nix 负责放置，APM 负责安装
      ".apm/apm.yml" = {
        source = ./apm.yml;
        force = true;
      };
    };

    # 全局 APM instructions — APM includes:auto 自动发现并编译到 CLAUDE.md
    # 新增 instruction 只需往 instructions/ 目录丢 .md 文件即可
    #    home.file.".apm/instructions" = {
    #      source = ./instructions;
    #      recursive = true;
    #      force = true;
    #    };
  };
}
