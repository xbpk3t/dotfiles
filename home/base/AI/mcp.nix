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
  # [2026-04-03] https://mynixos.com/home-manager/options/programs.mcp 最终是生成 $HOME/mcp/mcp.json 这么一个 mcp.json，跟目前所有cli都不一致（比如说 codex 的MCP的目标path就在config.toml, cc是 ~/.claude.json, cursor则是 $HOME/.cursor/mcp.json），所以没意义
  # [2026-04-03] 把mcp server由 mcp-servers-nix 管理，优势在于可以让 codex/cc 等所有cli复用一份mcp配置。带来的问题是 msn只有 command, args, env, url, headers 等通用字段，不支持codex的 approve 操作。
  # [2026-04-18] https://github.com/natsukium/mcp-servers-nix/issues/420 其实 MSN 是支持 approve 操作的，所以修改相应配置
  # [2026-04-18] 移除掉部分目前已经被主流agent（codex, cc）已经内置功能覆盖掉的mcp. sequential-thinking, ddg, octocode (被github mcp 替代), git (git操作已被主流agent完美支持), textlint, time (功能太简单，没必要)， memory (我其实并没有用这个 graph记忆，所以移除掉)

  imports = [
    inputs.mcp-servers-nix.homeManagerModules.default
  ];

  options.modules.AI.mcp = with lib; {
    isDesktop = mkEnableOption "desktop-only MCP servers (browser/GUI)";
  };

  # https://developers.openai.com/codex/mcp
  config = lib.mkIf mcpEnabled {
    programs.mcp.enable = true;

    home.packages = with pkgs; [
      # https://mynixos.com/nixpkgs/package/gitea-mcp-server
      # gitea-mcp-server

      # https://mynixos.com/nixpkgs/package/mcp-k8s-go
      # https://github.com/strowk/mcp-k8s-go
      # https://github.com/containers/kubernetes-mcp-server
      # mcp-k8s-go

      # https://mynixos.com/nixpkgs/package/aks-mcp-server
      # Azure Kubernetes Service
      # aks-mcp-server

      # https://mynixos.com/nixpkgs/package/fluxcd-operator-mcp
      # fluxcd-operator-mcp

      # https://mynixos.com/nixpkgs/package/markitdown-mcp
      # markitdown-mcp
    ];

    mcp-servers = {
      programs = {
        # filesystem MCP: 授权范围是整个 Home 目录，AI tool 可读写此目录下文件。
        # 如需最小权限，建议改成项目目录而不是 config.home.homeDirectory。
        # [2026-04-18] codex/cc 本身都可以通过 --add-dir 实现类似功能。但是其实我真正不想要的就是这个 --add-dir，会很麻烦，谁都跑到一半了，会因为没有某个folder的access权限，退出，然后重新resume+ add-dir进入？并且你说的也不对，设置home是有必要的，因为很多时候要搜索和操作的文件，也并不总是在上面这些path，我不可能为了以防万一加一堆path在这，懂吗？所以保留 filesystem，我需要保留这个全局默认可用的 $home 访问能力。
        filesystem = {
          enable = true;
          args = [ config.home.homeDirectory ];
        };

        fetch.enable = true;

        # https://mynixos.com/nixpkgs/package/mcp-nixos
        # [2026-04-26] build 失败，所以改为false
        # nixos.enable = false;

        # https://mynixos.com/nixpkgs/package/github-mcp-server
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

        # 先预留，按需启用。
        # serena.enable = true;
        # https://mynixos.com/nixpkgs/package/mcp-grafana
        # grafana.enable = true;

        # https://mynixos.com/nixpkgs/package/terraform-mcp-server
        # terraform.enable = true;

        # [2026-04-18] 用 chrome-devtools 替代掉了。playwright 更偏稳定自动化/脚本化操作，chrome-devtools 更偏调试、网络、console、性能、lighthouse、CDP 级观察。所以这组不是“完全同质”，但在日常使用中会明显抢同一个入口。
        # https://mynixos.com/nixpkgs/package/playwright-mcp
        #  playwright = {
        #    enable = true;
        #    # Darwin 下默认会走 pkgs.google-chrome，触发 Nix 构建 GoogleChrome-*.dmg。
        #    # 这里显式复用系统（brew 安装）的 Chrome，可避免重复下载/构建。
        #    executable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
        #  };
      };

      settings.servers = {
        # fetch 负责抓取页面内容
        # ddg 负责搜索
        # 严格说它们是上下游，不是同一个工具位；但从用户口径“帮我上网查资料”来看，它们经常服务同一个目标。也就是说，这组是工作流重叠，不是实现重叠。如果你偏向极简配置，这组也值得审视；但如果你希望“先搜索再打开”，保留两者是合理的。
        fetch = {
          default_tools_approval_mode = "approve";
        };

        # filesystem 可以列目录、读文件、搜索文件、读多文件、拿文件信息，甚至写改文件。filesystem 是通用文件系统能力。
        filesystem = {
          default_tools_approval_mode = "approve";
        };

        # https://github.com/johnhuang316/code-index-mcp
        # code-index 可以找文件、建索引、搜代码、拿 symbol body、文件摘要。code-index 是面向代码语义和索引的增强层。
        # [2026-04-19] 好像没什么人用，所以注释掉，之后再判断是否要移除掉
        #  "code-index" = {
        #    command = "uvx";
        #    args = ["code-index-mcp"];
        #    default_tools_approval_mode = "approve";
        #  };

        #  nixos = {
        #    startup_timeout_sec = 50;
        #    default_tools_approval_mode = "approve";
        #  };

        # https://github.com/ChromeDevTools/chrome-devtools-mcp
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
        # Future desktop-only entries (uncomment and add here):
        # "playwright" = lib.mkIf cfg.isDesktop { ... };   # needs browser
        # "bb-browser" = lib.mkIf cfg.isDesktop { ... };   # needs browser + login state

        # context7 偏库/框架文档
        context7 = {
          default_tools_approval_mode = "approve";
        };

        # https://linear.app/downloads/mcp
        #   把 LINEAR_API_KEY 提到 home.sessionVariables 后，MCP server 和 linear CLI都从同一个环境变量取值，消除了之前 bash -c wrapper 的冗余层。这遵循了 Nix管理凭据的标准模式——$(cat ${config.sops.secrets.XXX.path}) 在 shell启动时展开一次，所有子进程继承。
        # [2026-05-30] 注释掉该MCP，但要说明之前配置有问题 ① pnpm dlx 每次创建独立缓存。pnpm dlx 的 cache key 会根据当前项目目录的 package.json 算 hash。Claude 每次在不同工作目录（不同 worktree）启动 session，hash 不同 → 生成不同 cache 目录。即使 hash 相同，pnpm dlx 仍然 spawn 新的 node 进程。
        # "linear" = {
        #  command = ["linear-mcp"];
        #  default_tools_approval_mode = "approve";
        # };

        # https://github.com/colbymchenry/codegraph
        # CodeGraph: 基于 Tree-sitter 的代码知识图谱，构建本地 SQLite 索引后通过 MCP 工具暴露
        # search/explore/callers/impact 等能力给 AI agent 使用。
        # 二进制由 pnpm 全局安装管理 (~/.local/share/pnpm/bin/codegraph)，已包含在 PATH 中。
        #
        # MAYBE: [2026-05-26] Codex 侧 CodeGraph MCP 可见性待复查。
        # 已确认：CodeGraph server 配置符合 upstream Codex 示例，`codex mcp get codegraph`
        # 能识别该 server，Codex 日志里也能看到 CodeGraph MCP watcher 启动；Claude Code
        # 同一套 MCP 配置可以识别 CodeGraph 工具，手动 MCP tools/list 也能列出
        # codegraph_search/context/callers/impact 等工具。
        # 当前问题只出现在 Codex 模型可调用 tool schema 层：会话里看不到 codegraph_*。
        # 优先怀疑 `model_provider = "axonhub"` 的 Responses-compatible 路径没有正确透传动态
        # MCP tools，其次再排查 Codex 0.130.0 -> 最新版本的 MCP tool 注入差异。
        # 验证顺序：先临时移除默认 axonhub provider、走 Codex 官方默认 provider；若仍失败，
        # 再升级 Codex 并复测。不是 CodeGraph server 本身的接入配置问题。
        #
        # MAYBE: [2026-05-26] 目前codegraph不支持nix，等支持后用codegraph再扫一次本项目，并做优化
        # [feat: add Nix language support by uxtechie · Pull Request #330 · colbymchenry/codegraph](https://github.com/colbymchenry/codegraph/pull/330)
        "codegraph" = {
          command = "codegraph";
          args = [
            "serve"
            "--mcp"
          ];
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

        # https://github.com/epiral/bb-browser
        # bb-browser: 复用真实 Chrome 登录态的浏览器 MCP。
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

        #  terraform = {
        #  default_tools_approval_mode = "approve";
        #  };

        #  playwright = {
        #  default_tools_approval_mode = "approve";
        #  };

        # 先预留，按需启用（当前先注释）。
        # serena = {
        #  default_tools_approval_mode = "approve";
        # };
        # grafana = {
        # default_tools_approval_mode = "approve";
        # };
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
