{
  config,
  pkgs,
  lib,
  myvars,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
in {
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box service";
  };

  config = mkIf cfg.enable {
    # Install sing-box package for user
    environment.systemPackages = [pkgs.sing-box];

    # sing-box TUN 代理服务 (需要 root 权限创建 TUN 接口)
    launchd.daemons.sing-box-tun = {
      serviceConfig = {
        Label = "local.singbox.tun";
        ProgramArguments = [
          "${pkgs.sing-box}/bin/sing-box"
          "run"
          "-c"
          "/Users/${myvars.username}/config.json"
        ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
          NetworkState = true;
        };
        WorkingDirectory = "/tmp";
        StandardOutPath = "/Users/${myvars.username}/Library/Logs/sing-box.log";
        StandardErrorPath = "/Users/${myvars.username}/Library/Logs/sing-box.log";
        EnvironmentVariables = {
          PATH = "/etc/profiles/per-user/${myvars.username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          SING_BOX_LOG_LEVEL = "info";
        };
      };
    };
  };
}
