{config}: {
  # 本MCP配置，可以在codex和claude-code中复用

  filesystem = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-filesystem"
      config.home.homeDirectory
    ];
  };
  "sequential-thinking" = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-sequential-thinking"
    ];
  };
  memory = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-memory"
    ];
  };
  context7 = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@upstash/context7-mcp"
    ];
  };

  "nixos-mcp" = {
    type = "stdio";
    command = "uvx";
    args = ["mcp-nixos"];
    startup_timeout_sec = 50;
  };

  octocode = {
    type = "stdio";
    command = "pnpm";
    args = [
      "dlx"
      "octocode-mcp@latest"
    ];
    startup_timeout_sec = 30;
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

  "code-index" = {
    type = "stdio";
    command = "uvx";
    args = ["code-index-mcp"];
    startup_timeout_sec = 30;
  };
  "chrome-devtools" = {
    type = "stdio";
    command = "npx";
    args = ["-y" "chrome-devtools-mcp@latest"];
  };

  # [2026-01-09] 只保留HTTP版本，移除了stdio的本地版本
  github = {
    type = "http";
    url = "https://api.githubcopilot.com/mcp/";
    bearer_token_env_var = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN";
  };
}
