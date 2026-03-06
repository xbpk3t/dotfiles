{
  config,
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
      package = pkgs.codex;

      # https://github.com/openai/codex/blob/main/docs/config.md
      settings = {
        approval_policy = "on-request";
        sandbox_mode = "danger-full-access";
        file_opener = "cursor";
        network_access = true;
        exclude_tmpdir_env_var = false;
        exclude_slash_tmp = false;
        tui = {
          auto_mount_repo = true;
        };
        features = {
          web_search_request = true;
          streamable_shell = true;

          rmcp_client = true;
          unified_exec = true;
          view_image_tool = true;
        };
        mcp_servers = mcpServers;
      };
      custom-instructions = ''
      '';
    };

    home = {
      sessionVariables = {
        # https://github.com/openai/codex/issues/848
        CODEX_UNSAFE_ALLOW_NO_SANDBOX = 1;

        # For Context7 MCP
        CONTEXT7_API_KEY = "$(cat ${config.sops.secrets.API_context7.path})";
      };
      shellAliases = {
        codex = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) command codex";
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
