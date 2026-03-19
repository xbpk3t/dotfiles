{config}: {
  # 本MCP配置，可以在codex和claude-code中复用

  # TODO: programs.mcp ???
  # https://mynixos.com/home-manager/option/programs.mcp.servers
  # https://github.com/zhongjis/nix-config/blob/935ac824ed0c27868b9ae4e75753c8ad94508dd0/modules/home-manager/features/mcp.nix#L15

  # MAYBE: [2026-03-04] 等别人发 neo4j-mcp 了。官方3个方案：binary install, docker, 自己打包nixpkg. 前两种我不选，第三种嫌麻烦。当然mac上可以直接brew安装，但是不通用所以我也不选。
  # https://github.com/neo4j/mcp
  # https://neo4j.com/docs/mcp/current/

  # filesystem MCP: 授权范围是整个 Home 目录，AI tool 可读写此目录下文件。
  # 如需最小权限，建议改成项目目录而不是 config.home.homeDirectory。
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

  # startup_timeout_sec: 某些 Python/uvx MCP 首次 cold start 较慢，需要放宽超时。
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

  "code-index" = {
    type = "stdio";
    command = "uvx";
    args = ["code-index-mcp"];
    startup_timeout_sec = 30;
  };
  # Chrome 146+ 推荐使用 --autoConnect 附着当前浏览器实例。
  # 前置条件: chrome://inspect/#remote-debugging 已开启 Remote debugging。
  "chrome-devtools" = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "chrome-devtools-mcp@latest"
      "--autoConnect"
      "--channel"
      "stable"
    ];
  };

  # mcp-remote 代理模式: 本地 stdio <-> 远端 MCP over HTTP。
  deepwiki = {
    type = "stdio";
    command = "npx";
    args = ["-y" "mcp-remote" "https://mcp.deepwiki.com/mcp"];
  };

  # [2026-01-09] 只保留HTTP版本，移除了stdio的本地版本
  #  github = {
  #    type = "http";
  #    url = "https://api.githubcopilot.com/mcp/";
  #    bearer_token_env_var = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN";
  #  };
  # 注意: Authorization header 里是占位符，真实 token 由 shell alias 在运行时注入。
  # 不要把真实 PAT 写死到仓库配置中。
  github = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "mcp-remote"
      "https://api.githubcopilot.com/mcp/"
      "--transport"
      "http-only"
      "--header"
      "Authorization: Bearer YOUR_GITHUB_PAT"
    ];
  };
}
