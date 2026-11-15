{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modules.AI.skills;
in
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
  ];

  options.modules.AI.skills = with lib; {
    enable = mkEnableOption "Enable shared agent skills";
  };

  config = lib.mkIf cfg.enable {
    programs.agent-skills = {
      enable = true;
      sources = {
        local = {
          path = ./skills;
        };

        # opencli: `opencli-usage` 命令快速参考，用来插命令；
        # `opencli-browser` 驱动 Chrome 做交互式操作。
        # Upstream hint: `npx skills add jackwener/opencli`.
        opencli = {
          input = "opencli-skills";
          subdir = "skills";
        };

        # reclaim-code-entropy: 每提交数个 PR 后做一轮简化；搭配 cc 的 simplify 使用不错。
        # https://x.com/XchenEvan/status/2089268107269529657
        # https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/skills/dsh-find-simplifications/SKILL.md
        reclaim = {
          input = "reclaim-code-entropy-skills";
          subdir = "skills";
        };

        # plan-ceo-review: CEO/founder 模式 review（Step 0 前提挑战 + 四姿态 + adversarial 复核）。
        # https://x.com/wey_gu/status/2083773126660477417
        # 注意：SKILL.md 深度耦合 gstack 生态（office-hours/gbrain/telemetry/GSTACK REVIEW REPORT 输出），
        # 用于概念/文章等非执行任务时按需剪枝，不必挂 gstack 全家桶。
        #
        # NOTE: 暂时注释。ASN 只打包 skill 目录，不会带上 gstack 仓库根部的 bin/
        # （SKILL.md 引用 ~/.claude/skills/gstack/bin/...），直接启用会缺 telemetry /
        # review-log 等运行时脚本；等有 wrapper 或确认不需要这些脚本再打开。
        # gstack = {
        #   input = "gstack-skills";
        #   subdir = ".";
        #   filter.nameRegex = "plan-ceo-review";
        # };

        # security-audit: Cloudflare 官方六阶段源码审计（账本→isolated hunter→fresh verifier 推翻→三种裁决→独立复核）。
        # 显式要求 audit/pen-test 才跑全套，普通问题只走引导模式；无沙箱不执行目标代码。
        cloudflare-security = {
          input = "cloudflare-security-audit-skills";
          subdir = "skills";
        };
      };
      skills = {
        enableAll = [ "local" ];
        explicit = {
          opencli-usage = {
            from = "opencli";
            path = "opencli-usage";
          };
          opencli-browser = {
            from = "opencli";
            path = "opencli-browser";
          };
          reclaim-code-entropy = {
            from = "reclaim";
            path = "reclaim-code-entropy";
          };
          # plan-ceo-review 暂时注释，原因见 sources.gstack 上方。
          # plan-ceo-review = {
          #   from = "gstack";
          #   path = "plan-ceo-review";
          #   rename = "gstack/plan-ceo-review";
          # };
          security-audit = {
            from = "cloudflare-security";
            path = "security-audit";
          };
        };
      };
    };
  };
}
