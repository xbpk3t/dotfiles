{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.AI.codex;
in {
  # codex resume   打开可恢复的会话列表
  # codex resume --last 直接恢复当前工作目录下最近一次会话
  # codex resume --all 把当前目录之外的会话也列出来
  # codex resume <SESSION_ID>

  options.modules.AI.codex = with lib; {
    enable = mkEnableOption "Enable Codex";
  };

  # 中转站
  # https://www.helpaio.com/transit
  # https://cubence.com/
  # https://relaypulse.top/ 感觉 SSSAiCode 还不错（小月卡）
  # https://api.ikuncode.cc/console/topup gpt-5.4
  # 输入价格 ¥0.5000 / 1M Tokens
  # 补全价格 ¥3.0000 / 1M Tokens
  # 正好是 SSSAiCode 的一半
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
        model = "gpt-5.4";

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
        # 只有显式使用 `--profile ice|test|ggboom` 时，才切换到对应第三方 provider。

        # https://ldoh.105117.xyz/
        # 公益站自动签到
        # https://linux.do/t/topic/1001042/1117
        # https://github.com/qixing-jk/all-api-hub

        # https://linux.do/t/topic/1837955/39 在mac用开 ChatGPT Plus (用土区+礼品卡，¥80/月)
        model_providers = {
          # https://linux.do/t/topic/1806073
          # https://ice.v.ua/dashboard
          ice = {
            name = "ice";
            base_url = "https://ice.v.ua/v1";
            env_key = "OPENAI_API_KEY_ICE";
            wire_api = "responses";
          };

          # https://linux.do/t/topic/1558896
          # https://ai.qaq.al/dashboard
          # https://sign.qaq.al/app
          ggboom = {
            name = "ggboom";
            base_url = "https://ai.qaq.al/v1";
            env_key = "OPENAI_API_KEY_GGBoom";
            wire_api = "responses";
          };

          # https://linux.do/t/topic/1614522
          # https://openai.api-test.us.ci/console
          zzz = {
            name = "zzz";
            base_url = "https://new.api-test.us.ci/v1";
            env_key = "OPENAI_API_KEY_ZZZ";
            wire_api = "responses";
          };

          # https://linux.do/t/topic/1841046
          # https://freeapi.dgbmc.top/console/
          dgb = {
            name = "dgb";
            base_url = "https://freeapi.dgbmc.top/v1";
            env_key = "OPENAI_API_KEY_DGB";
            wire_api = "responses";
          };

          # https://linux.do/t/topic/1845022
          # https://windhub.cc/console/
          ark = {
            name = "ark";
            base_url = "https://windhub.cc/v1";
            env_key = "OPENAI_API_KEY_ARK";
            wire_api = "responses";
          };

          # https://linux.do/t/topic/1855760
          # https://free.9e.nz/dashboard
          kkk = {
            name = "kkk";
            base_url = "https://free.9e.nz/v1";
            env_key = "OPENAI_API_KEY_KKK";
            wire_api = "responses";
          };

          # https://codex.mqc.me/dashboard
          mqc = {
            name = "mqc";
            base_url = "https://claude.colin1112.tech/v1";
            env_key = "OPENAI_API_KEY_MQC";
            wire_api = "responses";
          };

          # https://linux.do/t/topic/1853293
          # https://muyuan.do/console/
          jun = {
            name = "jun";
            base_url = "https://muyuan.do/v1";
            env_key = "OPENAI_API_KEY_JUN";
            wire_api = "responses";
          };

          # https://elysiver.h-e.top/console
          ely = {
            name = "ely";
            # base_url = "https://elysia.h-e.top/v1";
            base_url = "https://elysiver.h-e.top/v1";
            env_key = "OPENAI_API_KEY_ELY";
            wire_api = "responses";
          };
        };

        profiles = {
          ice = {
            model_provider = "ice";
            model = "gpt-5.4";
          };

          ggboom = {
            model_provider = "ggboom";
            model = "gpt-5.4";
          };

          zzz = {
            model_provider = "zzz";
            model = "gpt-5.4";
          };

          dgb = {
            model_provider = "dgb";
            model = "gpt-5.4";
          };

          ark = {
            model_provider = "ark";
            model = "gpt-5.4";
          };

          kkk = {
            model_provider = "kkk";
            model = "gpt-5.4";
          };

          mqc = {
            model_provider = "mqc";
            model = "gpt-5.4";
          };

          jun = {
            model_provider = "jun";
            model = "gpt-5.4";
          };

          ely = {
            model_provider = "ely";
            model = "gpt-5.4";
          };
        };
      };
      custom-instructions = "";
    };

    home = {
      sessionVariables = {
        # https://github.com/openai/codex/issues/848
        # 允许 no-sandbox 模式运行。仅建议在可信本机环境使用。
        CODEX_UNSAFE_ALLOW_NO_SANDBOX = 1;

        # For Context7 MCP
        CONTEXT7_API_KEY = "$(cat ${config.sops.secrets.API_context7.path})";

        OPENAI_API_KEY_ICE = "$(cat ${config.sops.secrets.LLM_Sub2API_default.path})";

        OPENAI_API_KEY_GGBoom = "$(cat ${config.sops.secrets.LLM_Sub2API_ggboom.path})";

        OPENAI_API_KEY_ZZZ = "$(cat ${config.sops.secrets.LLM_Sub2API_zzz.path})";

        OPENAI_API_KEY_DGB = "$(cat ${config.sops.secrets.LLM_Sub2API_dgb.path})";

        OPENAI_API_KEY_ARK = "$(cat ${config.sops.secrets.LLM_Sub2API_ark.path})";

        OPENAI_API_KEY_KKK = "$(cat ${config.sops.secrets.LLM_Sub2API_default.path})";

        OPENAI_API_KEY_MQC = "$(cat ${config.sops.secrets.LLM_Sub2API_mqc.path})";

        OPENAI_API_KEY_JUN = "$(cat ${config.sops.secrets.LLM_Sub2API_jun.path})";

        OPENAI_API_KEY_ELY = "$(cat ${config.sops.secrets.LLM_Sub2API_ely.path})";
      };
      shellAliases = {
        # 每次启动 codex 时动态注入 GitHub PAT，避免把 token 写入静态配置。
        # codex = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) command codex";

        # 按需切换第三方 provider；不影响默认的 ChatGPT OAuth 登录态。

        # 用来切换profile
        codex-ice = "codex --profile ice";
        codex-gg = "codex --profile ggboom";
        codex-zzz = "codex --profile zzz";
        codex-dgb = "codex --profile dgb";
        codex-ark = "codex --profile ark";
        codex-kkk = "codex --profile kkk";

        codex-mqc = "codex --profile mqc";
        codex-jun = "codex --profile jun";
        codex-ely = "codex --profile ely";
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
