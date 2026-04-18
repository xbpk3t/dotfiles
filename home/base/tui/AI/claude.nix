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
          includeCoAuthoredBy = false;
          cleanupPeriodDays = 7;

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
            "thedotmack" = {
              source = {
                source = "github";
                repo = "thedotmack/claude-mem";
              };
            };
            # what: ClaudeClaw 插件市场
            "claudeclaw" = {
              source = {
                source = "github";
                repo = "moazbuilds/claudeclaw";
              };
            };
            # what: 社区 LSP 插件集合市场（含 nixd 等）
            "claude-code-lsps" = {
              source = {
                source = "github";
                repo = "Piebald-AI/claude-code-lsps";
              };
            };
          };

          # 插件启用清单（键格式：plugin-name@marketplace-name）
          enabledPlugins = {
            # what: Claude HUD（显示模型/上下文/token/git/todo 等状态）
            "claude-hud@claude-hud" = true;
            # what: Claude-Mem（压缩并回注会话上下文）
            "claude-mem@thedotmack" = true;
            # what: ClaudeClaw（扩展命令和工作流能力）
            "claudeclaw@claudeclaw" = true;
            # what: nixd LSP（Nix 语言服务）
            "nixd@claude-code-lsps" = true;
            # what: Swift LSP（来自官方 marketplace）
            # note: `claude-plugins-official` 为官方内置 marketplace，无需 extraKnownMarketplaces 再声明
            "swift-lsp@claude-plugins-official" = true;
          };

          # 降低运行噪音，避免额外 telemetry / survey 干扰
          env = {
            DISABLE_ERROR_REPORTING = "1";
            DISABLE_BUG_COMMAND = "1";
            CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
          };

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

          #  behavior = {
          #    autoSave = true;
          #    confirmOnExit = false;
          #    showLineNumbers = true;
          #  };
          permissions = {
            # 尽量与 codex 的 trusted projects 对齐，避免给到过宽目录。
            additionalDirectories = [
              "~/Desktop/dotfiles"
              "~/Desktop/docs"
            ];
            ask = [
              "Bash(git push:*)"
            ];
            deny = [];
            defaultMode = "plan";
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
          ANTHROPIC_AUTH_TOKEN = "$(cat ${config.sops.secrets.LLM_MetAPI.path})";
        };
        shellAliases = {
          # 默认 alias 保持权限模型生效，避免和 settings.permissions.defaultMode 冲突。
          cc = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) claude";
          # 兜底逃生开关：仅在明确需要跳过权限确认时手动使用。
          cc-unsafe = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) claude --dangerously-skip-permissions";
          ccr = "claude-code-router"; # Alias for claude-code-router
        };
      };

      home.packages = with pkgs; [
        # https://mynixos.com/nixpkgs/package/claude-code-router
        # claude-code-router
      ];

      # Claude HUD 的独立配置文件：
      # 插件会在 ~/.claude/plugins/claude-hud/config.json 读取行为和显示项。
      home.file.".claude/plugins/claude-hud/config.json".source = ./claude-hud-config.json;

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
  ];
}
