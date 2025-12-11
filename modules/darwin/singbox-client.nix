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
    # 定时更新配置，与主服务解耦
    launchd.daemons.singbox-update-config = {
      serviceConfig = {
        Label = "local.singbox.update-config";
        ProgramArguments = ["/etc/sing-box/update-config.sh"];

        # 系统启动后 5 分钟首次运行
        RunAtLoad = true;

        # 每 12 小时运行一次 (43200 秒)
        StartInterval = 43200;

        WorkingDirectory = "/tmp";
        StandardOutPath = "/Users/${myvars.username}/Library/Logs/sing-box-update.log";
        StandardErrorPath = "/Users/${myvars.username}/Library/Logs/sing-box-update.log";

        EnvironmentVariables = {
          PATH = "/etc/profiles/per-user/${myvars.username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    };

    # sing-box TUN 代理服务 (需要 root 权限创建 TUN 接口)
    # 主服务只负责运行 sing-box，不再负责下载配置
    launchd.daemons.sing-box-tun = {
      serviceConfig = {
        Label = "local.singbox.tun";
        ProgramArguments = [
          "${pkgs.sing-box}/bin/sing-box"
          "run"
          "-c"
          "/Users/${myvars.username}/.config/sing-box/config.json"
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
