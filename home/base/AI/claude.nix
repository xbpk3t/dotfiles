{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.modules.AI.claude;
in {
  options.modules.AI.claude = with lib; {
    enable = mkEnableOption "Enable Claude Code";
    permissionMode = mkOption {
      type = types.enum ["default" "yolo"];
      default = "default";
      description = ''
        Permission model for Claude Code:
        - "default": Interactive mode with fine-grained allow/ask/deny rules (workstation)
        - "yolo":    Headless/daemon mode with bypassPermissions (container agent)
      '';
    };
  };

  # https://github.com/AddG0/nix-config/blob/main/home/common/optional/development/ai/claude-code/default.nix
  # https://github.com/blessuselessk/determinate-OCD/blob/main/modules/lessuseless/claude.nix
  config = lib.mkMerge [
    {
      programs.claude-code.enableMcpIntegration = true;
    }
    (lib.mkIf cfg.enable {
      # https://mynixos.com/home-manager/options/programs.claude-code

      # https://x.com/yanhua1010/status/2044559129134698609
      programs.claude-code = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

        # https://x.com/xiangxiang103/status/2043612207175602671 cc 稳定不降智的技巧：换稳定性：关掉超长上下文、adaptive thinking、auto memory，确实更像“固定档位”了。适合长任务复现，但一般会牺牲一点探索效率。
        settings = {
          theme = "dark";
          outputStyle = "Explanatory";
          cleanupPeriodDays = 7;

          # 文件2建议：plan accept 页显示 clear context 按钮
          showClearContextOnPlanAccept = true;

          # 文件2建议：关掉离开 session 后的 recap，配合低噪音风格
          awaySummaryEnabled = false;

          # 文件2建议：真正关闭内置 auto memory（之前只禁了 claude-mem 插件，未关内置 auto memory）
          autoMemoryEnabled = false;

          # 走 Claude 原生插件生态：
          # 1) 先声明第三方 marketplace 来源（官方 marketplace 不需要声明）
          # 2) 再用 enabledPlugins 启用具体插件
          extraKnownMarketplaces = {
            # what: Claude HUD 状态栏增强插件市场
            # [可视化插件] 可以实时显示运行Claude状态：包括上下文使用情况、激活的Tools、MCP、运行中的subAgents以及todo list
            "claude-hud" = {
              source = {
                source = "github";
                repo = "jarrodwatts/claude-hud";
              };
            };
            # what: Claude-Mem 记忆插件市场
            #  "thedotmack" = {
            #    source = {
            #      source = "github";
            #      repo = "thedotmack/claude-mem";
            #    };
            #  };
            # what: ClaudeClaw 插件市场
            "claudeclaw" = {
              source = {
                source = "github";
                repo = "moazbuilds/claudeclaw";
              };
            };
            # what: 社区 LSP 插件集合市场（含 nixd 等）
            # https://github.com/Piebald-AI/claude-code-lsps
            "claude-code-lsps" = {
              source = {
                source = "github";
                repo = "Piebald-AI/claude-code-lsps";
              };
            };
            # what: tmux-agent-sidebar — 本地路径 marketplace
            # TPM 安装插件到 ~/.tmux/plugins/，用绝对路径避免 ~ 展开问题
            #  "hiroppy" = {
            #    source = {
            #      source = "directory";
            #      path = "${config.home.homeDirectory}/.tmux/plugins/tmux-agent-sidebar";
            #    };
            #  };
          };

          # 插件启用清单（键格式：plugin-name@marketplace-name）
          enabledPlugins = {
            # what: Claude HUD（显示模型/上下文/token/git/todo 等状态）
            "claude-hud@claude-hud" = true;

            # what: Claude-Mem（压缩并回注会话上下文）
            # [2026-04-29] 注释掉，总是往 AGENTS.md 里加入 <claude-mem-context>，另外我在使用 Trellis，所以不需要这个
            # "claude-mem@thedotmack" = true;

            # what: ClaudeClaw（扩展命令和工作流能力）
            "claudeclaw@claudeclaw" = true;

            # what: Swift LSP（来自官方 marketplace）
            # note: `claude-plugins-official` 为官方内置 marketplace，无需 extraKnownMarketplaces 再声明
            # "swift-lsp@claude-plugins-official" = true;

            "ralph-loop@claude-plugins-official" = true;

            # what: tmux-agent-sidebar（在 tmux 中显示 Claude Code 状态的 sidebar）
            # 由 tmux.nix 的 modules.devops.tmux.agentSidebar.enable 统一控制
            #  "tmux-agent-sidebar@hiroppy" = config.modules.devops.tmux.agentSidebar.enable;

            # 扫描你的项目并推荐：hooks → skills → MCP servers → subagents → automations 并做自动配置（感觉可以替代掉vercel/skills里的 find-skills了）
            "claude-code-setup@claude-plugins-official" = true;
          };

          env = {
            # 降低运行噪音，避免额外 telemetry / survey 干扰
            # 它等价于同时设置 DISABLE_AUTOUPDATER、DISABLE_FEEDBACK_COMMAND、DISABLE_ERROR_REPORTING、DISABLE_TELEMETRY。而且 survey 在 DISABLE_TELEMETRY 或 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 设置后也会被禁用。
            # 但这里仍显式列出关键开关，方便阅读和后续单独调整
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
            # 关闭 Sentry error reporting，也就是 Claude Code 自己崩溃、异常、错误日志上报。
            DISABLE_ERROR_REPORTING = "1";
            DISABLE_TELEMETRY = "1";

            # 关闭旧版 /feedback 反馈命令；旧变量名 DISABLE_BUG_COMMAND 仍兼容
            DISABLE_FEEDBACK_COMMAND = "1";
            # 关闭 “How is Claude doing?” 这种 session quality survey 弹窗/调查。官方也说如果设置了 DISABLE_TELEMETRY 或 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC，survey 也会被关掉。
            CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";

            # 文件2建议：隐藏购买额外用量命令，纯 UI 清理
            DISABLE_EXTRA_USAGE_COMMAND = "1";

            # 文件2建议：Nix 管 Claude Code 包版本，不需要它自己更新
            DISABLE_AUTOUPDATER = "1";
            # 文件2建议：不自动改终端 tab/window title
            CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
            # 建议新增：你用了 ANTHROPIC_BASE_URL 代理时，ToolSearch 默认会被关掉
            # | 值        | 行为                         | 我的判断                  |
            #| -------- | -------------------------- | --------------------- |
            #| `true`   | 永远 defer tools             | 激进，proxy 兼容性要求更高      |
            #| `auto`   | 工具占上下文不大时 upfront，否则 defer | 比较稳                   |
            #| `auto:5` | 超过 5% context 才 defer      | 更保守，适合 gateway        |
            #| `false`  | 全部 upfront load            | 最兼容，但 MCP 多时吃 context |
            # 文件2建议：true 太激进，auto:5 更保守（超过 5% context 才 defer），适合 gateway 环境
            ENABLE_TOOL_SEARCH = "auto:5";

            # [DS-V4-Pro， max模式很强，直接跳过high effort - 开发调优 - LINUX DO](https://linux.do/t/topic/2060808)
            # 关键：不要写 effortLevel = "max"，用 env 持久化 max
            # effortLevel 是否会耗费更多token?
            # 官方说 effort 会影响响应里的所有 token 消耗，包括文本解释、tool calls/function arguments、extended thinking；max 是“absolute maximum capability with no constraints on token spending”。但“多多少”没有固定倍数。原因是 effort 不是硬 token budget，而是行为信号；同一个任务可能只多一点，也可能因为更频繁思考、更多 tool call、更长分析链路而多很多。官方也明确说 max 适合最深推理，但可能收益递减、容易 overthinking，建议在采用为默认前测试。
            # 建议 claude --effort max 临时开启，或者在 prompt 里说 ultrathink。官方也提到 ultrathink 是单 turn 的 in-context 指令，不会改变 API effort level。
            # [2026-04-29] 从 max -> xhigh，避免耗费太多token
            CLAUDE_CODE_EFFORT_LEVEL = "max";

            # AnyRouter 的 claude-opus-4-7 已绑定 1M context，Claude Code 客户端必须通过 [1m] 后缀告知启用 1M 模式，
            # 否则请求会被 AnyRouter 拒绝（报 "1m 上下文已经全量可用，请启用 1m 上下文后重试"）。
            # [1m] 后缀在发往 provider 前会被 Claude Code 自动剥离，不影响上游模型名匹配。
            # 设置为默认model后，cc 默认使用这个model。需要用 --model去走自定义model
            ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-7[1m]";

            # 可选：通过 gateway 时，减少系统 prompt 中客户端归因头变化，有助于 gateway 层 prompt cache 命中
            CLAUDE_CODE_ATTRIBUTION_HEADER = "0";

            # 可选：你确实要用 experimental agent teams 再开
            # 实验功能：多 Claude Code session 协作。会显著增加 token，用时再开。
            # CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
          };

          # statusLine = {
          #   type = "command";
          #   command = "${pkgs.nushell}/bin/nu ${./claude-hud-wrapper.nu}";
          # };

          editor = {
            lineNumbers = true;
            wordWrap = true;
            minimap = false;
            theme = "auto";
          };

          # 默认不加 co-author
          attribution = {
            commit = "";
            pr = "";
          };
        };
      };

      home = {
        sessionVariables = {
          # 自定义 API 端点，用于连接到第三方模型服务
          #  ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
          #  # API 认证令牌 - 使用 sops 管理，通过 cat 命令读取文件内容
          #  ANTHROPIC_AUTH_TOKEN = "$(cat ${config.sops.secrets.API_GLM.path})";

          ANTHROPIC_BASE_URL = "https://api.lucc.dev";
          ANTHROPIC_AUTH_TOKEN = "$(cat ${config.sops.secrets.LLM_AxonHub.path})";
        };
        shellAliases = {
          # 默认 alias 保持权限模型生效，避免和 settings.permissions.defaultMode 冲突。
          cc = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) claude";

          # [2026-05-01] 注释掉了，默认cc直接bypassPermissions
          # 兜底逃生开关：仅在明确需要跳过权限确认时手动使用。
          # cc-unsafe = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) claude --dangerously-skip-permissions";

          ccr = "claude-code-router"; # Alias for claude-code-router

          # 文件2建议：复杂任务时临时开最高 effort，日常用 cc 保持 auto
          ccmax = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) claude --effort max";
        };
      };

      home.packages = with pkgs; [
        # https://mynixos.com/nixpkgs/package/claude-code-router
        # claude-code-router

        # claude-run: Claude Code 历史 Web viewer，文件1推荐
        # 不在 nixpkgs 中，用 npx wrapper 提供 claude-run 命令
        # 这种写法是否在每次rebuild时，都要重新安装？
        ## rebuild 不会触发重装：脚本本身是几字节的 Nix store 文件，npm 包只在首次执行时
        ## 下载到 ~/.npm/_npx/，之后走 npx cache；npm cache 和 Nix store 互不干扰
        # (writeShellApplication {
        #   name = "claude-run";
        #   runtimeInputs = [nodejs_20];
        #   text = ''
        #     exec npx --yes claude-run@0.3.0 "$@"
        #   '';
        # })
      ];

      # Claude HUD 的独立配置文件：
      # 插件会在 ~/.claude/plugins/claude-hud/config.json 读取行为和显示项。
      # TOML 源码可自由使用 # 注释；部署时 fromTOML → toJSON 纯 eval 转换。
      # home.file.".claude/plugins/claude-hud/config.json" = {
      #   force = true;
      #   text = builtins.toJSON (builtins.fromTOML (builtins.readFile ./claude-hud-config.toml));
      # };

      programs.agent-skills = {
        # Claude 和 Codex 复用同一份 skills 发布管道，避免两边手工维护两套分发逻辑。
        # 注意：这只代表“分发机制复用”，不代表“技能语义天然通用”。
        # 像 `ce-codex` 这类 agent 绑定技能，后续应按 agent 维度拆 catalog，而不是继续共用同一 skill 集。
        targets.claude = {
          enable = true;
          dest = ".claude/skills";
          structure = "link";
        };
      };
    })
    # 模式：default — 工作站交互式审批
    (lib.mkIf (cfg.enable && cfg.permissionMode == "default") {
      programs.claude-code.settings.permissions = {
        defaultMode = "plan";
        additionalDirectories = [
          "~/Desktop/dotfiles"
          "~/Desktop/docs"
        ];
        allow = [
          "Bash(*)"
          "Read(*)"
          "Edit(*)"
          "Write(*)"

          "WebSearch(*)"
          "WebFetch(*)"
          "Skill(*)"

          "mcp__*_chrome-devtools__*"
          "mcp__*_github__*"
          "mcp__*_linear__*"
          "mcp__*_codegraph__*"
        ];
        ask = [
          "Bash(git push *)"
          "Bash(git reset *)"
          "Bash(git clean *)"

          "Bash(rm *)"
          "Bash(sudo *)"
          "Bash(chmod *)"
          "Bash(chown *)"
          "Bash(dd *)"

          "Bash(npm publish *)"
          "Bash(pnpm publish *)"
          "Bash(cargo publish *)"

          "Bash(terraform apply *)"
          "Bash(terraform destroy *)"
          "Bash(tofu apply *)"
          "Bash(tofu destroy *)"

          "Bash(kubectl delete *)"
          "Bash(docker rm *)"
          "Bash(docker rmi *)"
          "Bash(docker system prune *)"
        ];
        deny = [];
      };
    })

    # 模式：yolo — 无值守 daemon 模式（容器 agent）
    (lib.mkIf (cfg.enable && cfg.permissionMode == "yolo") {
      programs.claude-code.settings.permissions = {
        defaultMode = "bypassPermissions";
        additionalDirectories = [
          "~/Desktop/dotfiles"
          "~/Desktop/docs"
        ];
        allow = [
          "Bash(*)"
          "Read(*)"
          "Edit(*)"
          "Write(*)"
          "WebSearch(*)"
          "WebFetch(*)"
          "Skill(*)"
          "mcp__*__*"
        ];
        ask = [];
        deny = [];
      };
    })
  ];
}
