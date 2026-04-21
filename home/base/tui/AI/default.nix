{...}: {
  imports = [
    ./mcp.nix
    ./codex.nix
    ./claude.nix
    ./opencode.nix
    ./skills.nix
  ];

  # MAYBE: [2026-04-21] 之后再判断是否要添加 rtk
  # https://github.com/rtk-ai/rtk
  # https://mynixos.com/nixpkgs/package/rtk 注意 llm-agents 本身支持 rtk
  # https://x.com/laogui/status/2045677115341934867
  # https://x.com/djdksnel/status/2044612252503011832
  # https://x.com/djdksnel/status/2045739787831881847
  # 暂不考虑添加 rtk，因为侵入性太强
  # 1) 要发挥 rtk 的核心价值（命令自动重写），必须接入 Claude 的 PreToolUse hook。
  # 2) 当前仓库已通过 programs.claude-code.settings 声明式管理 ~/.claude/settings.json，叠加 rtk init -g 产物会造成双源配置与行为冲突。
  # 3) hook 脚本需要长期跟踪 upstream 变更，维护和排障成本高于普通静态配置文件。
  # 4) 在没有明确收益数据前，先保持 AI 工具链行为可预测，避免引入全局命令改写副作用。
}
