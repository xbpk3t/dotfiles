{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  mcpEnabled =
    config.modules.AI.codex.enable
    || config.modules.AI.claude.enable
    || config.modules.AI.dsh.enable
    || config.modules.AI.opencode.enable;
  cfg = config.modules.AI.mcp;

  # Hosted HTTP MCP 端点的单一来源：url / token 环境变量 / CC header 形式。
  # 共享 settings.servers 与 programs.claude-code.mcpServers 都从这里取值，
  # 避免同一 URL 在 Codex 与 Claude 两份配置里各写一遍。
  hostedServers = {
    github = {
      url = "https://api.githubcopilot.com/mcp/";
      tokenEnv = "GITHUB_TOKEN";
      claudeHeaders.Authorization = "Bearer \${GITHUB_TOKEN}";
    };
    context7 = {
      url = "https://mcp.context7.com/mcp";
      tokenEnv = "CONTEXT7_API_KEY";
      claudeHeaders.CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
    };
    tavily = {
      url = "https://mcp.tavily.com/mcp/";
      tokenEnv = "TAVILY_API_KEY";
      claudeHeaders.Authorization = "Bearer \${TAVILY_API_KEY}";
    };
  };
  isHttp = name: builtins.elem name cfg.httpServers;
in
{
  imports = [
    inputs.mcp-servers-nix.homeManagerModules.default
  ];

  options.modules.AI.mcp = with lib; {
    isDesktop = mkEnableOption "desktop-only MCP servers (browser/GUI)";

    httpServers = mkOption {
      type = types.listOf (types.enum (builtins.attrNames hostedServers));
      default = [ ];
      description = ''
        Opt in to the hosted HTTP MCP endpoints for these servers instead of
        spawning local stdio processes. Default keeps the existing stdio path,
        so each host can choose independently (e.g. a 4G VPS opts in, while
        desktops keep stdio).

        Codex and dsh receive bearer_token_env_var; Claude Code receives
        per-server header overrides. Other clients may need their own auth wiring.
      '';
    };
  };

  # https://developers.openai.com/codex/mcp
  config = lib.mkIf mcpEnabled {
    programs = {
      mcp.enable = true;

      # Claude Code 专用：CC 不读 bearer_token_env_var；共享 server 的 headers 又会被
      # Codex 的 HM bridge 转成 http_headers（与 bearer_token_env_var 叠加 → 双 Authorization 400）。
      # 所以这里只覆盖 Claude 这一个 client，Codex 继续用上面的共享配置。
      # ${VAR} 由 CC 在读取 MCP 配置时展开，值来自 shell 的 LINEAR_API_KEY（见下方 sessionVariables）。
      claude-code.mcpServers = {
        linear = lib.mkIf config.modules.AI.claude.enable {
          type = "http";
          url = "https://mcp.linear.app/mcp";
          headers.Authorization = "Bearer \${LINEAR_API_KEY}";
          default_tools_approval_mode = "approve";
        };

        # Hosted HTTP variants for Claude Code. CC expands ${VAR} in headers;
        # shared settings.servers deliberately has no headers to avoid Codex's
        # HM bridge sending duplicate Authorization headers (see linear comment).
        context7 = lib.mkIf (config.modules.AI.claude.enable && isHttp "context7") {
          type = "http";
          inherit (hostedServers.context7) url;
          headers = hostedServers.context7.claudeHeaders;
          default_tools_approval_mode = "approve";
        };

        tavily = lib.mkIf (config.modules.AI.claude.enable && isHttp "tavily") {
          type = "http";
          inherit (hostedServers.tavily) url;
          headers = hostedServers.tavily.claudeHeaders;
          default_tools_approval_mode = "approve";
        };

        github = lib.mkIf (config.modules.AI.claude.enable && isHttp "github") {
          type = "http";
          inherit (hostedServers.github) url;
          headers = hostedServers.github.claudeHeaders;
          default_tools_approval_mode = "approve";
        };
      };
    };

    mcp-servers = {
      programs = {
        github = lib.mkIf (!isHttp "github") {
          enable = true;
          # github-mcp-server 只认 GITHUB_PERSONAL_ACCESS_TOKEN；用 wrapper 在
          # 启动时从 sops 读取，避免明文进 store，也让 dsh 的 stdio MCP 继承到。
          passwordCommand = {
            GITHUB_PERSONAL_ACCESS_TOKEN = [
              "cat"
              config.sops.secrets.GITHUB_TOKEN.path
            ];
          };
        };

        context7 = lib.mkIf (!isHttp "context7") {
          enable = true;
          passwordCommand = {
            CONTEXT7_API_KEY = [
              "cat"
              config.sops.secrets.API_CONTEXT7.path
            ];
          };
        };

        # Tavily: 通用网页搜索 MCP（替代被第三方网关废掉的 Anthropic 服务端 WebSearch）。
        # 走第三方 API，不经 Anthropic 后端 → DeepSeek 网关下照常可用。
        # key 注入用 passwordCommand（进程启动时 wrap 一层注入），与 context7 同一规范，
        # 不依赖 shell 是否导出了 TAVILY_API_KEY；勿改用 env 硬编码（store 可被任意读）。
        tavily = lib.mkIf (!isHttp "tavily") {
          enable = true;
          passwordCommand = {
            TAVILY_API_KEY = [
              "cat"
              config.sops.secrets.API_TAVILY.path
            ];
          };
        };
      };

      settings.servers = {

        # 默认改为让 MCP 自己拉起受控 Chrome，而不是附着当前正在使用的浏览器。
        # Why:
        # - `--autoConnect` 依赖 chrome://inspect/#remote-debugging 的握手与授权弹窗，实际更脆；
        # - 当前机器上的默认 Chrome 暴露的 9222 端点并不是标准可消费的 DevTools discovery 接口；
        # - 让 MCP 自己启动独立 profile 的 Chrome，是 upstream 默认路径，也更容易验证是否工作正常。
        # 包直接用 mcp-servers-nix 提供的 `chrome-devtools-mcp`（overlay 暴露为 pkgs.chrome-devtools-mcp）。
        # 不用它的 `programs.chrome-devtools` module：该 module 在 Darwin 默认拉
        # pkgs.google-chrome 并强制传 --executable-path，会改变这里让 MCP 自己
        # 发现系统 Chrome 的行为；只复用 package，保持现有 MCP 配置。
        # Desktop-only MCPs: require browser/GUI environment.
        # Add new desktop-only servers inside this mkIf block.
        "chrome-devtools" = lib.mkIf cfg.isDesktop {
          command = "${pkgs.chrome-devtools-mcp}/bin/chrome-devtools-mcp";
          args = [ ];
          default_tools_approval_mode = "approve";
        };

        # Hosted GitHub MCP：host 通过 modules.AI.mcp.httpServers opt in。
        # bearer_token_env_var 由支持它的 client（Codex / dsh）读取；Claude
        # 用下面的专用 headers 覆盖（shared 层不放 headers，见 linear 注释）。
        github = lib.mkIf (isHttp "github") {
          type = "http";
          inherit (hostedServers.github) url;
          bearer_token_env_var = hostedServers.github.tokenEnv;
          default_tools_approval_mode = "approve";
        };

        # context7 偏库/框架文档。默认 stdio；host opt in 后走 hosted HTTP。
        context7 = {
          default_tools_approval_mode = "approve";
        }
        // lib.optionalAttrs (isHttp "context7") {
          type = "http";
          inherit (hostedServers.context7) url;
          bearer_token_env_var = hostedServers.context7.tokenEnv;
        };

        # Tavily 通用搜索：approve 免审批，与同文件其它 server 一致。
        # tool 属 MCP（mcp__* 前缀），不在 claude.nix 的显式 allow 列表里时靠这里放行。
        # 默认 stdio；host opt in 后走 hosted HTTP。
        tavily = {
          default_tools_approval_mode = "approve";
        }
        // lib.optionalAttrs (isHttp "tavily") {
          type = "http";
          inherit (hostedServers.tavily) url;
          bearer_token_env_var = hostedServers.tavily.tokenEnv;
        };

        # https://linear.app/docs/mcp
        #   Linear MCP 是远程 HTTP MCP（`https://mcp.linear.app/mcp`），走 native HTTP transport。
        #
        #   认证方式分流（2026-11-16 重新确认）：
        #   - Codex: 共享配置里的 bearer_token_env_var 让它读 env 发 Authorization，OOTB 工作。
        #   - Claude Code: 用下面的 programs.claude-code.mcpServers.linear 专用覆盖，
        #     headers.Authorization = "Bearer ${LINEAR_API_KEY}"。CC 支持 ${VAR} 展开，
        #     Linear 官方也接受 API key 作为 Bearer；不再走 OAuth。
        #   - 不要把 headers 加到共享 server：Codex 的 HM bridge 会把 headers 映射成
        #     http_headers，与 bearer_token_env_var 叠加会发两个 Authorization → 400。
        #   [2026-07-11] 之前用 Codex 的 {env:...} 模板测 CC，语法不对导致 401，已纠正。
        #   [2026-06-12] 使用 streamable HTTP（与 deepwiki 相同模式），零本地进程开销。
        "linear" = {
          type = "http";
          url = "https://mcp.linear.app/mcp";
          default_tools_approval_mode = "approve";
        }
        // lib.optionalAttrs config.modules.AI.codex.enable {
          bearer_token_env_var = "LINEAR_API_KEY";
        };

        # https://docs.devin.ai/work-with-devin/deepwiki-mcp
        # [2026-04-19] 因为是remote mcp，在init时很耗时
        # [2026-05-28] 重新添加了，确实很有用
        # deepwiki 偏公开 repo/wiki/远程 MCP 知识访问；现有 fetch/github/context7/codegraph 不能完全替代。
        # 使用直接 streamable HTTP，避免 npx + mcp-remote 的本地代理启动开销。
        # 远端网络/服务延迟仍然存在；如果之后启动体验明显变差，再改为按需启用。
        deepwiki = {
          type = "http";
          url = "https://mcp.deepwiki.com/mcp";
          startup_timeout_sec = 100;
          default_tools_approval_mode = "approve";
        };

        # deja-vu: local session-history MCP (recall / recall_context / blame / remember).
        # Why declarative here instead of `deja install claude-code`:
        # - HM owns MCP via mcp-servers-nix + programs.claude-code.enableMcpIntegration;
        # - install would write imperative ~/.claude.json and fight Nix.
        # No hooks (SessionStart/PreCompact/UserPromptSubmit): index refresh is manual
        #   `deja warmup` / `deja index`. Skill guidance is separate (Claude-only SKILL.md).
        # Binary: Homebrew short-term. MCP spawn often lacks interactive PATH → abs path.
        # Follow-up: package deja-vu in flake and switch command to ${pkgs...}/bin/deja.
        deja = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          command = "/opt/homebrew/bin/deja";
          args = [ "mcp" ];
          type = "stdio";
          default_tools_approval_mode = "approve";
        };

        # 这次选择它，不是因为它比 skill“更酷”，而是因为浏览器能力更适合作为 MCP 能力层接入。
        # upstream README 直接给出了 MCP 用法：`npx -y bb-browser --mcp`。
        # 与 chrome-devtools 的边界：
        # - chrome-devtools 偏通用 CDP / DevTools 调试与页面观察
        # - bb-browser 偏“真实浏览器 + 登录态 + 站点适配 + AI 直接取数/操作”
        # 暂不显式配置 tools：先保持默认 prompt。
        # 原因是 bb-browser 的 tool 清单需要在实际接入后通过 `codex mcp get bb-browser` 再精确补全。
        #  "bb-browser" = {
        #    command = "npx";
        #    args = [
        #      "-y"
        #      "bb-browser"
        #      "--mcp"
        #    ];
        #  };
      };
    };

    # Share API keys with MCP servers and CLI tools.
    # sessionVariables are sourced by the shell; MCP server subprocess inherits them.
    # GITHUB_TOKEN is already exported by home/core/devops/gh.nix.
    home.sessionVariables = {
      LINEAR_API_KEY = "$(cat ${config.sops.secrets.API_LINEAR.path})";
      CONTEXT7_API_KEY = "$(cat ${config.sops.secrets.API_CONTEXT7.path})";
      TAVILY_API_KEY = "$(cat ${config.sops.secrets.API_TAVILY.path})";
      EXA_API_KEY = "$(cat ${config.sops.secrets.API_EXA.path})";
      KEENABLE_API_KEY = "$(cat ${config.sops.secrets.API_KEENABLE.path})";
    };
  };
}
