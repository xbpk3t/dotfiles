{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.AI.codex;
  codexDefaultModel = "gpt-5.5";
  mcpServersForCodex =
    (
      inputs.mcp-servers-nix.lib.evalModule pkgs {
        inherit
          (config.mcp-servers)
          programs
          settings
          ;
        flavor = "codex";
      }
    ).config.settings.servers;
in {
  # codex resume   打开可恢复的会话列表
  # codex resume --last 直接恢复当前工作目录下最近一次会话
  # codex resume --all 把当前目录之外的会话也列出来
  # codex resume <SESSION_ID>

  options.modules.AI.codex = with lib; {
    enable = mkEnableOption "Enable Codex";
  };

  config = lib.mkIf cfg.enable {
    # https://mynixos.com/home-manager/options/programs.codex
    # https://github.com/openai/codex
    programs.codex = {
      enable = true;
      # [2026-04-18] 关闭 HM bridge 到 programs.mcp.servers 的自动整合：
      # mcp-servers-nix 在 HM bridge 下会裁剪 server 字段，仅保留 command/args/env/url/headers。
      # codex 专有字段（如 tools.*.approval_mode、startup_timeout_sec）需要直接放在 mcp_servers 里。
      enableMcpIntegration = false;
      # package = pkgs.codex;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;

      # https://github.com/openai/codex/blob/main/docs/config.md
      # https://developers.openai.com/codex/config-reference
      settings = {
        # 默认模型；可被命令行 `-m` 临时覆盖。
        model = codexDefaultModel;
        # 显式固定 reasoning，避免 provider 元数据把 gpt-5.5 默认值显示为 medium。
        model_reasoning_effort = "xhigh";
        plan_mode_reasoning_effort = "xhigh";

        # on-request: 默认命令先在 sandbox 内执行，超权限时再请求批准。
        # [2026-04-08] 我原本的需求是：现在切换到 mcp-servers-nix 之后，无法默认approve全部这些MCP操作，所以想要通过该配置进行配置。事实证明该配置项无法实现该需求。
        approval_policy = "on-request";
        # danger-full-access: 关闭 filesystem sandbox，适合你当前本机自动化场景，但风险更高。
        sandbox_mode = "danger-full-access";
        file_opener = "cursor";
        network_access = true;
        exclude_tmpdir_env_var = false;
        exclude_slash_tmp = false;
        tui = {
          auto_mount_repo = true;
        };
        features = {
          # [features].web_search_request` is deprecated because web search is enabled by default.
          # web_search_request = true;
          # streamable_shell/unified_exec 用于更稳定的命令流式输出与 PTY 交互。
          streamable_shell = true;

          # 如果日志出现 "unknown feature key"，通常是 Codex 版本与配置键不匹配。
          # 可在升级 codex 后保留；若持续告警且无功能收益，可删掉对应键。
          rmcp_client = true;
          unified_exec = true;
          view_image_tool = true;

          # fast_mode 对应 service_tier=fast；当前默认开启，按需用 CLI/config 临时覆盖。
          fast_mode = true;

          # ralph loop
          goals = true;

          # For Trellis (to approve the Trellis UserPromptSubmit hook)
          hooks = true;
        };
        # 声明式 trusted projects：避免首次进入仓库时反复询问 trust。
        projects = {
          "${config.home.homeDirectory}/Desktop/docs/dotfiles" = {
            trust_level = "trusted";
          };
          "${config.home.homeDirectory}/Desktop/docs" = {
            trust_level = "trusted";
          };
        };

        # 默认 provider 固定为 axonhub，和当前 workstation/provider 事实保持一致。
        # 如需临时回到 Codex 官方登录态或其他 provider，用 CLI/profile 覆盖，不把它写成默认路径。

        # [2026-04-18] 直接注入 mcp-servers-nix 的 codex flavor server 配置。
        # 这样 settings.servers.<name>.tools.*.approval_mode 可以原样进入 Codex 的 mcp_servers。
        mcp_servers = mcpServersForCodex;

        model_provider = "axonhub";
        model_providers = {
          axonhub = {
            name = "axonhub";
            base_url = "https://api.lucc.dev/v1";
            env_key = "LLM_AxonHub";
            wire_api = "responses";
          };
        };

        # profiles 用于显式切换/覆盖；默认路径本身也指向 axonhub。
        profiles = {
          axonhub = {
            model_provider = "axonhub";
            model = codexDefaultModel;
          };
        };
      };
    };

    home = {
      sessionVariables = {
        # https://github.com/openai/codex/issues/848
        # 允许 no-sandbox 模式运行。仅建议在可信本机环境使用。
        CODEX_UNSAFE_ALLOW_NO_SANDBOX = 1;

        # For Context7 MCP
        CONTEXT7_API_KEY = "$(cat ${config.sops.secrets.API_CONTEXT7.path})";

        LLM_AxonHub = "$(cat ${config.sops.secrets.LLM_AxonHub.path})";
      };
      shellAliases = {
      };
    };

    # Allow Home Manager to overwrite ~/.codex/config.toml without backups/prompts
    home.file.".codex/config.toml".force = true;

    #  home.file.".codex/prompts" = {
    #    source = ./prompts;
    #    recursive = true;
    #    force = true;
    #  };

    programs.agent-skills = {
      # 注意这个 targets 是用来把 skills folder 放到不同cli工具的folder，以实现skills的复用。所以所有这里配置了的 targets 里的 skills 都是完全一致的。
      targets.codex = {
        enable = true;
        # dest = ".agents/skills";
        dest = ".codex/skills";
        # link keeps the local skills catalog single-sourced through ASN.
        # If Codex skill discovery regresses on symlinks, switch this target to copy-tree and document the repro.
        structure = "link";
      };
    };
  };
}
