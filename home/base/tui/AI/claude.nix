{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.AI.claude;
  mcpServers = import ./mcp-servers.nix {inherit config;};
in {
  options.modules.AI.claude = with lib; {
    enable = mkEnableOption "Enable Claude Code";
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
      settings = {
        theme = "dark";
        outputStyle = "Explanatory";
        includeCoAuthoredBy = false;
        cleanupPeriodDays = 7;

        editor = {
          lineNumbers = true;
          wordWrap = true;
          minimap = false;
          theme = "auto";
        };
        #  behavior = {
        #    autoSave = true;
        #    confirmOnExit = false;
        #    showLineNumbers = true;
        #  };
        mcpServers = mcpServers;
        permissions = {
          additionalDirectories = [
            "~/Desktop"
          ];
          ask = [
            "Bash(git push:*)"
          ];
          deny = [];
          defaultMode = "plan";
        };
      };
    };

    home = {
      sessionVariables = {
        # 自定义 API 端点，用于连接到第三方模型服务
        ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
        # API 认证令牌 - 使用 sops 管理，通过 cat 命令读取文件内容
        ANTHROPIC_AUTH_TOKEN = "$(cat ${config.sops.secrets.API_GLM.path})";
      };
      shellAliases = {
        cc = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) claude --dangerously-skip-permissions";
        ccr = "claude-code-router"; # Alias for claude-code-router
      };
    };
  };
}
