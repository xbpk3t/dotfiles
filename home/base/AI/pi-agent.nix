{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.pi-agent;
in
{
  options.modules.AI.pi-agent = with lib; {
    enable = mkEnableOption "Enable pi coding agent";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.pi-coding-agent
      ];

      sessionVariables = {
        # 与 codex/claude 共用同一组 API key，走 sops 加密
        LLM_AxonHub = "$(cat ${config.sops.secrets.LLM_AxonHub.path})";
      };

      # Pi 的配置入口是 JSON 文件。settings.json 控制主 provider、theme 以及插件路径。
      file.".pi/agent/settings.json".text = builtins.toJSON {
        defaultProvider = "axonhub";
        defaultModel = "gpt-5.5";
        theme = "dark";

        # packages 声明 Pi package spec（npm:、git:、本地路径），
        # Pi 会在启动时自动安装/加载对应资源合集。
        packages = [ ];

        # 以下四类路径声明插件的资源目录，Pi 会从中加载扩展能力
        extensions = [
          "~/.config/pi/extensions"
        ];

        #  skills = [
        #    "~/.config/pi/skills"
        #  ];
        #
        #  prompts = [
        #    "~/.config/pi/prompts"
        #  ];
        #
        #  themes = [
        #    "~/.config/pi/themes"
        #  ];
      };

      # models.json 声明 axonhub provider，与 codex/claude 共用 API 和密钥。
      file.".pi/agent/models.json".text = builtins.toJSON {
        providers = {
          axonhub = {
            baseUrl = "https://api.lucc.dev/v1";
            api = "openai-responses";
            # Pi 的 resolveConfigValue 会把值当 env var 名查，找不到才作字面量
            apiKey = "LLM_AxonHub";
            models = [
              { id = "gpt-5.5"; }
              { id = "gpt-5.4"; }
              { id = "deepseek-v4-pro"; }
              { id = "deepseek-v4-flash"; }
            ];
          };
        };
      };
    };
  };
}
