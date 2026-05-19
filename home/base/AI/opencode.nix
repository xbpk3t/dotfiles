{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.AI.opencode;
in {
  options.modules.AI.opencode = with lib; {
    enable = mkEnableOption "Enable OpenCode";
  };

  config = lib.mkIf cfg.enable {
    # https://mynixos.com/home-manager/options/programs.opencode
    # themes: using stylix
    # https://github.com/code-yeongyu/oh-my-openagent
    # https://github.com/code-yeongyu/oh-my-opencode/blob/dev/README.zh-cn.md

    # OMO
    # https://linux.do/t/topic/1624433
    #
    # MAYBE: [2026-01-19](opencode) 之后如果有了OMO的flake，再做nix化。
    # 有了OMO之后，就不需要对opencode的其他配置（通过nix）做预配置了。完全由OMO处理（本身会处理 settings/agents/provider/plugin）
    #
    # [opencode-go 的订阅，这不是吊打国模官方原版？ - 搞七捻三 - LINUX DO](https://linux.do/t/topic/1806924/14) 是否要订阅 opencode-go
    # https://linux.do/t/topic/1573713/4
    # https://linux.do/t/topic/1585272/11
    #
    # oh-my-opencode
    #
    # bunx oh-my-opencode install
    #
    # [OpenCode 速查表 - 文档共建 - LINUX DO](https://linux.do/t/topic/1719460)
    programs.opencode = {
      # 是否启用 opencode
      enable = true;

      # 使用的 opencode 包
      package = pkgs.opencode;
    };

    home.shellAliases = {
      "oc" = "opencode";
    };
  };
}
