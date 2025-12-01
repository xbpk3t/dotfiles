{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  hostSystem = pkgs.stdenv.hostPlatform.system;
  mcpPackages = inputs.mcp-servers-nix.packages.${hostSystem};
  mkStdIO = pkg: {
    type = "stdio";
    command = lib.getExe pkg;
  };
  McpServers = {
    filesystem = mkStdIO mcpPackages.mcp-server-filesystem;
    "sequential-thinking" = mkStdIO mcpPackages.mcp-server-sequential-thinking;
    memory = mkStdIO mcpPackages.mcp-server-memory;
    "nixos-mcp" = mkStdIO pkgs.mcp-nixos;
    octocode = {
      type = "stdio";
      command = "pnpm";
      args = [
        "dlx"
        "octocode-mcp@latest"
      ];
    };
    ddg = {
      type = "stdio";
      command = "pnpm";
      args = [
        "dlx"
        "duckduckgo-mcp-server"
      ];
    };
    deepwiki = {
      type = "http";
      url = "https://mcp.deepwiki.com/mcp";
    };
    context7 = mkStdIO mcpPackages.context7-mcp;
    github = {
      type = "http";
      url = "https://api.githubcopilot.com/mcp/";
    };
    "code-index" = {
      type = "stdio";
      command = "uvx";
      args = ["code-index-mcp"];
    };
    "chrome-devtools" = {
      type = "stdio";
      command = "npx";
      args = ["-y" "chrome-devtools-mcp@latest"];
    };
    "github-mcp" = {
      type = "stdio";
      command = lib.getExe pkgs.github-mcp-server;
      env = {
        GITHUB_PERSONAL_ACCESS_TOKEN = "$GITHUB_TOKEN";
      };
    };
  };
in {
  # https://github.com/numtide/nix-ai-tools
  home.packages =
    (with inputs.nix-ai-tools.packages.${hostSystem}; [
      claude-code-router

      # [2025-11-13] No longer use qwen
      # qwen-code

      # https://github.com/github/spec-kit
      spec-kit
    ])
    ++ (with pkgs; [
      # https://mynixos.com/nixpkgs/package/github-mcp-server
      github-mcp-server

      # https://mynixos.com/nixpkgs/package/mcp-nixos
      mcp-nixos

      # https://mynixos.com/nixpkgs/package/gitea-mcp-server
      gitea-mcp-server

      # https://mynixos.com/nixpkgs/package/playwright-mcp
      playwright-mcp

      # https://mynixos.com/nixpkgs/package/terraform-mcp-server
      terraform-mcp-server

      # https://mynixos.com/nixpkgs/package/mcp-k8s-go
      mcp-k8s-go

      # https://mynixos.com/nixpkgs/package/aks-mcp-server
      aks-mcp-server

      # https://mynixos.com/nixpkgs/package/mcp-grafana
      mcp-grafana

      # https://mynixos.com/nixpkgs/package/fluxcd-operator-mcp
      fluxcd-operator-mcp
    ])
    ++ [pkgs.ruler];

  home = {
    sessionVariables = {
      # 自定义 API 端点，用于连接到第三方模型服务
      ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
      # API 认证令牌 - 使用 sops 管理，通过 cat 命令读取文件内容
      ANTHROPIC_AUTH_TOKEN = config.sops.secrets.claudeZaiToken.path;

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
      package = inputs.nix-ai-tools.packages.${hostSystem}.codex;

      # https://github.com/openai/codex/blob/main/docs/config.md
      settings = {
        approval_policy = "on-request";
        sandbox_mode = "danger-full-access";
        file_opener = "cursor";
        network_access = true;
        exclude_tmpdir_env_var = false;
        exclude_slash_tmp = false;
        tui = {
          auto_mount_repo = true;
        };
        features = {
          web_search_request = true;
          streamable_shell = true;
          rmcp_client = true;
          unified_exec = true;
          view_image_tool = true;
        };
        mcp_servers = McpServers;
      };
      custom-instructions = ''
      '';
    };

    claude-code = {
      enable = true;
      package = inputs.nix-ai-tools.packages.${hostSystem}.claude-code;
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
        mcpServers = McpServers;
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
