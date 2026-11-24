{
  config,
  globals,
  lib,
  ...
}:
let
  cfg = config.modules.AI.opencode;
  webCfg = cfg.web;
in
{
  options.modules.AI.opencode = with lib; {
    enable = mkEnableOption "OpenCode";

    web = {
      enable = mkEnableOption "OpenCode web service";

      bindAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address the OpenCode web server binds to.";
      };

      port = mkOption {
        type = types.port;
        default = 4096;
        description = "Port the OpenCode web server listens on.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.opencode = {
        enable = true;

        # 与 claude/codex/dsh 复用同一份 programs.mcp.servers，避免四端漂移。
        enableMcpIntegration = true;

        settings = {
          # 网关是 OpenAI-compatible；[1m] 是 Claude Code 侧标记，这里用裸 id。
          model = "axonhub/${globals.models.dsf}";

          provider.axonhub = {
            npm = "@ai-sdk/openai-compatible";
            name = "AxonHub";
            options = {
              baseURL = "${globals.llmGateway}/v1";
              # 密钥由 web service 的 environmentFile 注入，不进 Nix store。
              apiKey = "{env:AXONHUB_API_KEY}";
            };
            models.${globals.models.dsf}.name = globals.models.dsf;
          };
        };
      };
    })

    # 只有显式开 web 的 host 才生成 systemd/launchd 服务与 sops 环境文件。
    (lib.mkIf (cfg.enable && webCfg.enable) {
      programs.opencode.web = {
        enable = true;
        extraArgs = [
          "--hostname"
          webCfg.bindAddress
          "--port"
          (toString webCfg.port)
        ];
        environmentFile = config.sops.templates."opencode-env".path;
      };

      # v1 用 OPENCODE_SERVER_PASSWORD（不是新文档里的 OPENCODE_PASSWORD）。
      # 复用 me/sk，避免新增 secret；AXONHUB_API_KEY 供 provider 的 {env:...} 解析。
      sops.templates."opencode-env".content = ''
        OPENCODE_SERVER_PASSWORD=${config.sops.placeholder.ME_SK}
        AXONHUB_API_KEY=${config.sops.placeholder.LLM_AxonHub}
      '';
    })
  ];
}
