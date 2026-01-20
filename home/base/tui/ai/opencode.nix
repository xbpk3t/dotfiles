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
    # https://github.com/code-yeongyu/oh-my-opencode/blob/dev/README.zh-cn.md
    #
    # MAYBE[2026-01-19](opencode): 之后如果有了OMO的flake，再做nix化。
    # 有了OMO之后，就不需要对opencode的其他配置（通过nix）做预配置了。完全由OMO处理（本身会处理 settings/agents/provider/plugin）
    #
    #
    # oh-my-opencode
    #
    # bunx oh-my-opencode install
    #
    #
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
