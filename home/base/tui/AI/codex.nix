{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.AI.codex;
  codexPrompts = pkgs.runCommandLocal "codex-prompts" {} ''
    mkdir -p "$out"

    cp -R ${inputs.ce-codex}/prompts/. "$out"/
    cp -R ${./prompts}/. "$out"/
  '';
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
      enableMcpIntegration = true;
      # package = pkgs.codex;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;

      # https://github.com/openai/codex/blob/main/docs/config.md
      # https://developers.openai.com/codex/config-reference
      settings = {
        # 默认模型；可被命令行 `-m` 临时覆盖。
        # model = "gpt-5.4";
        model = "gpt-5.3-codex";

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
        };
        # 声明式 trusted projects：避免首次进入仓库时反复询问 trust。
        projects = {
          "${config.home.homeDirectory}/Desktop/dotfiles" = {
            trust_level = "trusted";
          };
          "${config.home.homeDirectory}/Desktop/docs" = {
            trust_level = "trusted";
          };
        };

        # 默认不声明 model_provider，让 Codex 继续走本地 ChatGPT OAuth 登录态。否则会报错 Error: Model provider `` not found
        # 只有显式使用 `--profile metapi` 时，才切换到对应第三方 provider。

        model_provider = "metapi";
        model_providers = {
          metapi = {
            name = "metapi";
            base_url = "https://api.lucc.dev/v1";
            env_key = "LLM_MetAPI";
            wire_api = "responses";
          };
        };

        # [2026-04-14] profiles 是用来创建可切换的命名方案。因为把所有provider都由 MetAPI管理，所以不再需要了
        #  profiles = {
        #    metapi = {
        #      model_provider = "metapi";
        #      model = "gpt-5.4";
        #    };
        #  };
      };
      custom-instructions = "";
    };

    home = {
      sessionVariables = {
        # https://github.com/openai/codex/issues/848
        # 允许 no-sandbox 模式运行。仅建议在可信本机环境使用。
        CODEX_UNSAFE_ALLOW_NO_SANDBOX = 1;

        # For Context7 MCP
        CONTEXT7_API_KEY = "$(cat ${config.sops.secrets.API_CONTEXT7.path})";

        LLM_MetAPI = "$(cat ${config.sops.secrets.LLM_MetAPI.path})";
      };
      shellAliases = {
        # 每次启动 codex 时动态注入 GitHub PAT，避免把 token 写入静态配置。
        # codex = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) command codex";

        # 按需切换第三方 provider；不影响默认的 ChatGPT OAuth 登录态。
      };
    };

    # Allow Home Manager to overwrite ~/.codex/config.toml without backups/prompts
    home.file.".codex/config.toml".force = true;

    home.file.".codex/prompts" = {
      source = codexPrompts;
      recursive = true;
      force = true;
    };
  };
}
