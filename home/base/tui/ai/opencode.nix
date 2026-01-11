{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.AI.opencode;
in {
  options.modules.AI.opencode = with lib; {
    enable = mkEnableOption "Enable OpenCode";
  };

  config = lib.mkIf cfg.enable {
    # https://mynixos.com/home-manager/options/programs.opencode
    # themes: using stylix
    programs.opencode = {
      # 是否启用 opencode
      enable = true;

      # 使用的 opencode 包
      package = pkgs.opencode;

      # 全局自定义规则
      rules = [
        "回答前先给出一句话结论"
        "修改文件前先列出变更清单"
      ];

      # 写入 opencode.json 的基础配置
      settings = {
        # JSON Schema 地址
        "$schema" = "https://opencode.ai/config.json";

        # 默认主题
        theme = "opencode";

        # 自动更新策略
        autoupdate = true;

        # 默认模型
        model = "opencode/gpt-5.1-codex";

        # 轻量模型
        small_model = "opencode/gpt-5.1-codex";

        # 默认 Agent
        default_agent = "build";

        # 分享策略
        share = "manual";

        # 全局工具开关
        tools = {
          # 是否允许写文件
          write = true;

          # 是否允许编辑文件
          edit = true;

          # 是否允许执行命令
          bash = true;
        };
      };

      # 自定义 agents
      agents = {
        # 代码审查 Agent
        review = {
          # Agent 描述
          description = "代码审查";

          # Agent 使用的模型
          model = "opencode/gpt-5.1-codex";

          # Agent 提示词
          prompt = "你是代码审查者，关注安全、性能与可维护性。";

          # Agent 工具权限
          tools = {
            # 禁止写文件
            write = false;

            # 禁止编辑文件
            edit = false;

            # 禁止执行命令
            bash = false;
          };
        };
      };

      # 自定义 commands
      commands = {
        # 快速测试命令
        test = {
          # 命令模板
          template = "运行完整测试并汇总失败用例，给出修复建议。";

          # 命令描述
          description = "运行测试并给出修复建议";

          # 使用的 Agent
          agent = "build";

          # 覆盖默认模型
          model = "opencode/gpt-5.1-codex";
        };
      };
    };
  };
}
