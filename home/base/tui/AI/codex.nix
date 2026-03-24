{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.AI.codex;
  mcpServers = import ./mcp-servers.nix {inherit config;};
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
      # package = pkgs.codex;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;

      # https://github.com/openai/codex/blob/main/docs/config.md
      settings = {
        # 默认模型；可被命令行 `-m` 临时覆盖。
        model = "gpt-5.4";
        # on-request: 默认命令先在 sandbox 内执行，超权限时再请求批准。
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
        };
        # MCP servers 统一从 ./mcp-servers.nix 导入，避免散落在多个文件。
        mcp_servers = mcpServers;

        # 声明式 trusted projects：避免首次进入仓库时反复询问 trust。
        projects = {
          "${config.home.homeDirectory}/Desktop/dotfiles" = {
            trust_level = "trusted";
          };
          "${config.home.homeDirectory}/Desktop/docs" = {
            trust_level = "trusted";
          };
        };

        # 注意这里特意留空，因为我目前主力仍然使用 team的OAuth，这里如果设置provider后，就无法切换到team了
        model_provider = "";
        model_providers = {
          # https://linux.do/t/topic/1806073
          ice = {
            name = "ice";
            base_url = "https://ice.v.ua";
            env_key = "OPENAI_API_KEY_ICE";
            wire_api = "responses";
          };

          # https://linux.do/t/topic/1806866
          test = {
            name = "test";
            base_url = "http://119.8.113.226:9999/";
            env_key = "OPENAI_API_KEY_TEST";
            wire_api = "responses";
          };

          # https://linux.do/t/topic/1558896
          # https://ai.qaq.al/dashboard
          ggboom = {
            name = "ggboom";
            base_url = "https://ai.qaq.al";
            env_key = "OPENAI_API_KEY_GGBoom";
            wire_api = "responses";
          };
        };

        profiles = {
          ice = {
            model_provider = "ice";
            model = "gpt-5.4";
          };

          test = {
            model_provider = "test";
            model = "gpt-5.4";
          };

          ggboom = {
            model_provider = "ggboom";
            model = "gpt-5.4";
          };
        };
      };
      custom-instructions = ''
      '';
    };

    home = {
      sessionVariables = {
        # https://github.com/openai/codex/issues/848
        # 允许 no-sandbox 模式运行。仅建议在可信本机环境使用。
        CODEX_UNSAFE_ALLOW_NO_SANDBOX = 1;

        # For Context7 MCP
        CONTEXT7_API_KEY = "$(cat ${config.sops.secrets.API_context7.path})";

        OPENAI_API_KEY_ICE = "$(cat ${config.sops.secrets.LLM_Sub2API_ICE.path})";

        OPENAI_API_KEY_TEST = "$(cat ${config.sops.secrets.LLM_Sub2API_TEST.path})";

        OPENAI_API_KEY_GGBoom = "$(cat ${config.sops.secrets.LLM_Sub2API_GGBoom.path})";
      };
      shellAliases = {
        # 每次启动 codex 时动态注入 GitHub PAT，避免把 token 写入静态配置。
        codex = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) command codex";
        # 按需切换第三方 provider；不影响默认的 ChatGPT OAuth 登录态。

        # 用来切换profile
        codex-ice = "codex --profile ice";
        codex-test = "codex --profile test";
        codex-gg = "codex --profile ggboom";
      };
    };

    # Allow Home Manager to overwrite ~/.codex/config.toml without backups/prompts
    home.file.".codex/config.toml".force = true;

    home.file.".codex/prompts" = {
      source = ./prompts;
      recursive = true;
      force = true;
    };
  };
}
