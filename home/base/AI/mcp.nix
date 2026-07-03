{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  mcpEnabled = config.modules.AI.codex.enable || config.modules.AI.claude.enable;
  cfg = config.modules.AI.mcp;
in
{
  imports = [
    inputs.mcp-servers-nix.homeManagerModules.default
  ];

  options.modules.AI.mcp = with lib; {
    isDesktop = mkEnableOption "desktop-only MCP servers (browser/GUI)";
  };

  # https://developers.openai.com/codex/mcp
  config = lib.mkIf mcpEnabled {
    programs.mcp.enable = true;

    mcp-servers = {
      programs = {
        github = {
          enable = true;
        };

        context7 = {
          enable = true;
          passwordCommand = {
            CONTEXT7_API_KEY = [
              "cat"
              config.sops.secrets.API_CONTEXT7.path
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
        # 这里继续调用仓库内自打包的 `pkgs.chrome-devtools-mcp`，而不是 `npx ...@latest`。
        # Why:
        # - 这个仓库已经有自维护 `pkgs/` 入口，适合把常用 MCP server 纳入 declarative 管理；
        # - upstream npm tarball 已经带预编译产物，直接打包发布物比每次运行时走 npx 下载更稳，也更符合当前仓库的打包选型；
        # - 版本升级统一交给 nvfetcher，避免 MCP 启动时再发生隐式在线更新。
        # Desktop-only MCPs: require browser/GUI environment.
        # Add new desktop-only servers inside this mkIf block.
        "chrome-devtools" = lib.mkIf cfg.isDesktop {
          command = "${pkgs.chrome-devtools-mcp}/bin/chrome-devtools-mcp";
          args = [ ];
          default_tools_approval_mode = "approve";
        };

        # context7 偏库/框架文档
        context7 = {
          default_tools_approval_mode = "approve";
        };

        # https://linear.app/docs/mcp
        #   Linear MCP 是远程 HTTP MCP（`https://mcp.linear.app/mcp`），走 native HTTP transport。
        #   把 LINEAR_API_KEY 提到 home.sessionVariables 后，MCP server 子进程自动继承。
        #   这遵循了 Nix 管理凭据的标准模式——$(cat ${config.sops.secrets.XXX.path}) 在 shell
        #   启动时展开一次，所有子进程继承。
        #   [2026-06-12] 使用 streamable HTTP（与 deepwiki 相同模式），零本地进程开销。
        "linear" = {
          type = "http";
          url = "https://mcp.linear.app/mcp";
          default_tools_approval_mode = "approve";
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
    home.sessionVariables = {
      LINEAR_API_KEY = "$(cat ${config.sops.secrets.API_LINEAR.path})";
      TAVILY_API_KEY = "$(cat ${config.sops.secrets.API_TAVILY.path})";
      EXA_API_KEY = "$(cat ${config.sops.secrets.API_EXA.path})";
    };
  };
}
