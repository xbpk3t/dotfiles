{
  pkgs,
  lib,
  ...
}: let
  # 自动发现 cc 目录中的命令文件
  subagentsDir = ./cc/subagents;
  agents =
    lib.mapAttrs'
    (
      fileName: _:
        lib.nameValuePair
        (lib.removeSuffix ".md" fileName)
        (builtins.readFile (subagentsDir + "/${fileName}"))
    )
    (builtins.readDir subagentsDir);

  commandsDir = ./cc/commands;
  commands =
    lib.mapAttrs'
    (
      fileName: _:
        lib.nameValuePair
        (lib.removeSuffix ".md" fileName)
        (builtins.readFile (commandsDir + "/${fileName}"))
    )
    (builtins.readDir commandsDir);
in {
  # Claude Code 程序配置
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    # 使用自动发现的命令
    commands = commands;
    agents = agents;

    mcpServers = {
      "nixos-mcp" = {
        command = "uvx";
        args = ["mcp-nixos"];
      };

      deepwiki = {
        type = "sse";
        url = "https://mcp.deepwiki.com/sse";
      };
    };

    # 编辑器和行为设置
    settings = {
      editor = {
        lineNumbers = true;
        wordWrap = true;
        minimap = false;
        theme = "auto";
      };
      behavior = {
        autoSave = true;
        confirmOnExit = false;
        showLineNumbers = true;
      };

      allow = [
        "WebFetch(domain:docs.anthropic.com)"
        "Bash(rm:*)"
        "WebFetch(domain:github.com)"
        "mcp__context7__resolve-library-id"
        "mcp__context7__get-library-docs"
        "mcp__filesystem__list_directory"
        "Bash(grep:*)"
        "Bash(git add:*)"
        "mcp__filesystem__edit_file"
        "mcp__filesystem__search_files"
        "Bash(mv:*)"
        "Bash(sed:*)"
        "Bash(git push:*)"
        "Bash(find:*)"
        "Bash(rg:*)"
        "Bash(git commit:*)"
        "Bash(git status:*)"
        "Bash(git diff:*)"
        "Bash(git log:*)"
        "WebFetch(domain:api.github.com)"
        "WebFetch"
        "Bash(chmod:*)"
        "Bash(mkdir:*)"
        "Bash(cp:*)"
        "Bash(ls:*)"
        "Bash(cd:*)"
        "Bash(pwd:*)"
        "Bash(echo:*)"
        "Bash(cat:*)"
        "Bash(head:*)"
        "Bash(tail:*)"
        "mcp__deepwiki__read_wiki_structure"
        "mcp__deepwiki__read_wiki_contents"
        "mcp__deepwiki__ask_question"
      ];
      deny = [];
    };
  };

  # 添加 Claude CLI 和相关工具包
  home.packages = [
  ];

  # Claude CLI 环境变量配置
  home.sessionVariables = {
    # 自定义 API 端点，用于连接到第三方模型服务
    ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
    # API 认证令牌 - 使用 sops 管理 (存储文件路径，避免时序问题)
    ANTHROPIC_AUTH_TOKEN = "/etc/claude/zai/token";
  };

  # Shell 配置 - 添加 Claude Code 相关的 shell 功能
  programs.bash.initExtra = ''
  '';
}
