{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.modules.AI.skills;
in {
  imports = [
    inputs.agent-skills.homeManagerModules.default
  ];

  options.modules.AI.skills = with lib; {
    enable = mkEnableOption "Enable agent skills for Codex";
  };

  config = lib.mkIf cfg.enable {
    # https://github.com/ymat19/dotfiles/blob/main/modules/ai-agent.nix
    # https://github.com/edmundmiller/dotfiles/blob/main/skills/flake.nix
    # https://github.com/ryoppippi/dotfiles/blob/main/nix/modules/home/agent-skills.nix
    # https://github.com/mikinovation/dotfiles/blob/main/config/nix/configs/agent-skills.nix
    # https://github.com/mikinovation/dotfiles/blob/main/config/nix/flake.nix
    # https://github.com/i9wa4/dotfiles/blob/main/nix/home-manager/modules/agent-skills.nix
    programs.agent-skills = {
      enable = true;
      sources = {
        local = {
          path = ./skills;
        };

        # https://github.com/antfu/skills
        antfu = {
          path = inputs.antfu-skills;
          subdir = "skills";
        };

        anthropic = {
          path = inputs.anthropic-skills;
          subdir = "skills";
        };

        agent-browser = {
          path = inputs.agent-browser;
          subdir = "skills";
        };

        # https://github.com/vercel-labs/agent-skills
        # what: 用于 React 组合模式 相关任务
        # what: 用于 vercel 部署 相关任务
        # what: 用于 React/Next.js 性能最佳实践 相关任务
        # what: 用于 React Native 最佳实践 相关任务
        # what: 用于 Web 设计规范 相关任务
        vercel-skills = {
          path = inputs.vercel-skills;
          subdir = "skills";
        };

        obra-superpowers = {
          path = inputs.obra-superpowers;
          subdir = "skills";
        };

        # skills 为空时会安装该 repo 的全部 skills（依赖 skills CLI 默认行为）
        # https://github.com/Leonxlnx/taste-skill
        # https://x.com/vikingmute/status/2025842815721497009
        # what: 用于 设计 taste frontend 相关任务
        #        leonxlnx-taste-skill = {
        #          path = inputs.leonxlnx-taste-skill;
        #          subdir = ".";
        #        };
        #
        #        jimliu-baoyu-skills = {
        #          path = inputs.jimliu-baoyu-skills;
        #          subdir = ".";
        #        };
        #
        #        # https://github.com/ast-grep/agent-skill
        #        # https://skills.sh/ast-grep/agent-skill
        #        ast-grep-agent-skill = {
        #          path = inputs.ast-grep-agent-skill;
        #          subdir = "ast-grep/skills";
        #        };
        #
        #        # https://github.com/wshobson/agents
        #        wshobson-agents = {
        #          path = inputs.wshobson-agents;
        #          subdir = "plugins";
        #        };
        #
        #        # https://github.com/onmax/nuxt-skills
        #        onmax-nuxt-skills = {
        #          path = inputs.onmax-nuxt-skills;
        #          subdir = "skills";
        #        };
        #
        #        # https://github.com/sanyuan0704/code-review-expert
        #        # https://x.com/GitHub_Daily/status/2020346913690906774
        #        # what: 用于 Code Review 专家 相关任务
        #        # why: 领域偏量化/交易
        #        sanyuan0704-code-review-expert = {
        #          path = inputs.sanyuan0704-code-review-expert;
        #          subdir = "skills";
        #        };
        #
        #        # https://github.com/millionco/react-doctor
        #        # https://x.com/QingQ77/status/2023954643076985302
        #        # what: 用于 动画最佳实践 相关任务
        #        # what: 用于 React 诊断 相关任务
        #        # what: 用于 Remotion 最佳实践 相关任务
        #        # why: 领域偏视频/动画
        #        # - remotion-best-practices
        #        millionco-react-doctor = {
        #          path = inputs.millionco-react-doctor;
        #          subdir = ".";
        #        };
        #
        #        # https://skills.sh/paulirish/dotfiles/modern-css
        #        # https://skills.sh/lucifer1004/claude-skill-typst
        #        lucifer1004-claude-skill-typst = {
        #          path = inputs.lucifer1004-claude-skill-typst;
        #          subdir = "skills";
        #        };
        #
        #        # https://skills.sh/ypares/agent-skills
        #        ypares-agent-skills = {
        #          path = inputs.ypares-agent-skills;
        #          subdir = ".";
        #        };
        #
        #        # https://skills.sh/github/awesome-copilot/plantuml-ascii
        #        github-awesome-copilot = {
        #          path = inputs.github-awesome-copilot;
        #          subdir = "skills";
        #        };
        #
        #        # https://skills.sh/softaworks/agent-toolkit/mermaid-diagrams
        #        softaworks-agent-toolkit = {
        #          path = inputs.softaworks-agent-toolkit;
        #          subdir = "skills";
        #        };
        #
        #        # https://skills.sh/404kidwiz/claude-supercode-skills
        #        404kidwiz-claude-supercode-skills = {
        #          path = inputs.404kidwiz-claude-supercode-skills;
        #          subdir = ".";
        #        };
        #
        #        # https://skills.sh/slidevjs/slidev
        #        slidevjs-slidev = {
        #          path = inputs.slidevjs-slidev;
        #          subdir = "skills";
        #        };
        #
        #        # https://skills.sh/silvainfm/claude-skills
        #        # https://skills.sh/silvainfm/claude-skills/duckdb
        #        silvainfm-claude-skills = {
        #          path = inputs.silvainfm-claude-skills;
        #          subdir = ".";
        #        };
        #
        #        # https://skills.sh/hashicorp/agent-skills
        #        hashicorp-agent-skills = {
        #          path = inputs.hashicorp-agent-skills;
        #          subdir = ".";
        #        };
        #
        #        # https://skills.sh/hustcer/nushell-pro
        #        hustcer-nushell-pro = {
        #          path = inputs.hustcer-nushell-pro;
        #          subdir = ".";
        #        };
        #
        #        # https://skills.sh/hustcer/nushell-craft
        #        # TODO: [2026-03-06] 注意这两个重复了，持续关注之后author怎么处理。这两个repo只需要保留一个即可。
        #        hustcer-nushell-craft = {
        #          path = inputs.hustcer-nushell-craft;
        #          subdir = ".";
        #        };
      };
      skills = {
        # enableAll = [ "local" ];
        enableAll = true;
        #        enable = [
        #          "find-skills"
        #          "skill-creator"
        #          "agent-browser"
        #          "git-commit"
        #          "git-organize-commits"
        #          "git-pick-changes"
        #          "git-pr"
        #          "team-dev"
        #          "vue-best-practices"
        #          "nuxt"
        #          "test-driven-development"
        #        ];

        # explicit
      };

      targets.codex = {
        enable = true;
        dest = ".codex/skills";
        # 技术要点：copy-tree 避免 symlink 在部分工具/环境中失效
        #        structure = "copy-tree";
        # structure = "link";
        # structure = "symlink-tree";
      };
    };
  };
}
