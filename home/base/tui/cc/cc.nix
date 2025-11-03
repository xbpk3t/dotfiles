{
  filesystem = {
    type = "stdio";
    command = "pnpm";
    args = [
      "dlx"
      "@modelcontextprotocol/server-filesystem"
    ];
  };
  "sequential-thinking" = {
    type = "stdio";
    command = "pnpm";
    args = [
      "dlx"
      "@modelcontextprotocol/server-sequential-thinking"
    ];
  };
  memory = {
    type = "stdio";
    command = "pnpm";
    args = [
      "dlx"
      "@modelcontextprotocol/server-memory"
    ];
  };
  "nixos-mcp" = {
    type = "stdio";
    command = "uvx";
    args = ["mcp-nixos"];
  };
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
  context7 = {
    type = "http";
    url = "https://mcp.context7.com/mcp";
  };
  github = {
    type = "http";
    url = "https://api.githubcopilot.com/mcp/";
  };
  "claude-task-master" = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "task-master-ai"
    ];
    env = {
      ANTHROPIC_API_KEY = "$(cat /etc/sk/claude/zai/token)";
    };
  };
  "code-index" = {
    type = "stdio";
    command = "uvx";
    args = ["code-index-mcp"];
  };
  "github-mcp" = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@github/github-mcp-server"
    ];
    env = {
      GITHUB_PERSONAL_ACCESS_TOKEN = "$(cat /etc/sk/claude/github-token)";
    };
  };
  # https://github.com/ChromeDevTools/chrome-devtools-mcp
  "chrome-devtools" = {
    type = "stdio";
    command = "npx";
    args = ["-y" "chrome-devtools-mcp@latest"];
  };
}
