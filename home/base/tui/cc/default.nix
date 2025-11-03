{
  pkgs,
  inputs,
  ...
}: {
  # https://github.com/numtide/nix-ai-tools
  home.packages =
    (with inputs.nix-ai-tools.packages.${pkgs.system}; [
      claude-code-router
      qwen-code

      # https://github.com/github/spec-kit
      spec-kit
    ])
    ++ [pkgs.ruler];

  home = {
    sessionVariables = {
      # 自定义 API 端点，用于连接到第三方模型服务
      ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
      # API 认证令牌 - 使用 sops 管理，通过 cat 命令读取文件内容
      ANTHROPIC_AUTH_TOKEN = "$(cat /etc/sk/claude/zai/token)";

      # https://github.com/openai/codex/issues/848
      CODEX_UNSAFE_ALLOW_NO_SANDBOX = 1;
    };
    shellAliases = {
      cc = "claude --dangerously-skip-permissions";
      ccr = "claude-code-router"; # Alias for claude-code-router
    };
  };

  programs = {
    # https://mynixos.com/home-manager/options/programs.codex
    codex = {
      enable = true;
      package = inputs.nix-ai-tools.packages.${pkgs.system}.codex;

      # https://github.com/openai/codex/blob/main/docs/config.md
      settings = import ./codex.nix;
      custom-instructions = ''
      '';
    };

    claude-code = {
      enable = true;
      package = inputs.nix-ai-tools.packages.${pkgs.system}.claude-code;
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
        mcpServers = import ./cc.nix;
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
  };
}
