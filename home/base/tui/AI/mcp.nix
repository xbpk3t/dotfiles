{
  config,
  inputs,
  lib,
  ...
}: let
  mcpEnabled =
    config.modules.AI.codex.enable
    || config.modules.AI.claude.enable;
in {
  # [2026-04-03] 把mcp server由 mcp-servers-nix 管理，优势在于可以让 codex/cc 等所有cli复用一份mcp配置。带来的问题是 msn只有 command, args, env, url, headers 等通用字段，不支持codex的 approve 操作。

  imports = [
    inputs.mcp-servers-nix.homeManagerModules.default
  ];

  # MAYBE: [2026-04-03](excalidraw-mcp)
  # https://github.com/excalidraw/excalidraw-mcp Excalidraw MCP，这个更适合拿来想事情，尤其是流程图、系统结构这类内容，靠文字说不清的时候，画一下会快很多。

  # MAYBE: [2026-03-04](neo4j-mcp) 等别人发 neo4j-mcp 了。官方3个方案：binary install, docker, 自己打包nixpkg. 前两种我不选，第三种嫌麻烦。当然mac上可以直接brew安装，但是不通用所以我也不选。
  # https://github.com/neo4j/mcp
  # https://neo4j.com/docs/mcp/current/

  # MAYBE: [2026-04-03](stitch MCP)
  # https://linux.do/t/topic/1832590
  # https://github.com/davideast/stitch-mcp
  # https://stitch.withgoogle.com/docs/mcp/setup

  config = lib.mkIf mcpEnabled {
    programs.mcp.enable = true;

    mcp-servers = {
      programs = {
        # filesystem MCP: 授权范围是整个 Home 目录，AI tool 可读写此目录下文件。
        # 如需最小权限，建议改成项目目录而不是 config.home.homeDirectory。
        filesystem = {
          enable = true;
          args = [config.home.homeDirectory];
        };
        memory.enable = true;
        context7.enable = true;
        sequential-thinking.enable = true;
      };

      settings.servers = {
        "nixos-mcp" = {
          command = "uvx";
          args = ["mcp-nixos"];
          startup_timeout_sec = 50;
        };

        octocode = {
          command = "pnpm";
          args = [
            "dlx"
            "octocode-mcp@latest"
          ];
        };

        ddg = {
          command = "pnpm";
          args = [
            "dlx"
            "duckduckgo-mcp-server"
          ];
        };

        "code-index" = {
          command = "uvx";
          args = ["code-index-mcp"];
        };

        # Chrome 146+ 推荐使用 --autoConnect 附着当前浏览器实例。
        # 前置条件: chrome://inspect/#remote-debugging 已开启 Remote debugging。
        "chrome-devtools" = {
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
        # 暂不显式配置 tools：先保持默认 prompt。
        # 原因是远端 tool 清单可能随服务端变化，后续可在 `codex mcp get deepwiki` 后再精确补全。
        deepwiki = {
          command = "npx";
          args = [
            "-y"
            "mcp-remote"
            "https://mcp.deepwiki.com/mcp"
          ];
        };

        # [2026-01-09] 只保留HTTP版本，移除了stdio的本地版本
        #  github = {
        #    type = "http";
        #    url = "https://api.githubcopilot.com/mcp/";
        #    bearer_token_env_var = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN";
        #  };
        # 注意: Authorization header 里是占位符，真实 token 由 shell alias 在运行时注入。
        # 不要把真实 PAT 写死到仓库配置中。
        # 暂不显式配置 tools：官方 GitHub MCP 可能包含写操作，先保持默认 prompt 更稳妥。
        # 如果后续确认只想放行只读工具，再根据 `codex mcp get github` 的实际清单精确声明。
        github = {
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

        # https://github.com/epiral/bb-browser
        # bb-browser: 复用真实 Chrome 登录态的浏览器 MCP。
        # 这次选择它，不是因为它比 skill“更酷”，而是因为浏览器能力更适合作为 MCP 能力层接入。
        # upstream README 直接给出了 MCP 用法：`npx -y bb-browser --mcp`。
        # 与 chrome-devtools 的边界：
        # - chrome-devtools 偏通用 CDP / DevTools 调试与页面观察
        # - bb-browser 偏“真实浏览器 + 登录态 + 站点适配 + AI 直接取数/操作”
        # 暂不显式配置 tools：先保持默认 prompt。
        # 原因是 bb-browser 的 tool 清单需要在实际接入后通过 `codex mcp get bb-browser` 再精确补全。
        "bb-browser" = {
          command = "npx";
          args = [
            "-y"
            "bb-browser"
            "--mcp"
          ];
        };
      };
    };
  };
}
