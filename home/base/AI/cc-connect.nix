{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.AI.cc-connect;
in
{
  options.modules.AI.cc-connect = with lib; {
    enable = mkEnableOption "Enable cc-connect daemon (brew-installed)";
  };

  config = lib.mkIf cfg.enable {
    # cc-connect config deployed to ~/.cc-connect/config.toml
    home.file.".cc-connect/config.toml".source = ./cc-connect.toml;

    home.sessionVariables = {
      FEISHU_APP_SECRET = "$(cat ${config.sops.secrets.FEISHU_APP_SECRET.path})";
    };

    # LaunchAgent to keep cc-connect running
    launchd.agents.cc-connect = {
      enable = true;
      config = {
        EnvironmentVariables = {
          CC_LOG_FILE = "/Users/luck/.cc-connect/logs/cc-connect.log";
          PATH = "/opt/homebrew/bin:/etc/profiles/per-user/luck/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };

        ProgramArguments = [
          "/opt/homebrew/bin/cc-connect"
          "--config"
          "/Users/luck/.cc-connect/config.toml"
        ];

        KeepAlive = true;
        RunAtLoad = true;

        WorkingDirectory = "/Users/luck/.cc-connect";

        StandardOutPath = "/Users/luck/.cc-connect/logs/stdout.log";
        StandardErrorPath = "/Users/luck/.cc-connect/logs/stderr.log";
      };
    };
  };
}
