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
    environment.systemPackages = [pkgs.sing-box pkgs.curl pkgs.jq];

    # Create a script to download sing-box configuration with retry logic
    # 独立的配置下载脚本，与 sing-box 主服务解耦
    environment.etc."sing-box/update-config.sh" = {
      text = ''
        #!/bin/sh
        set -euo pipefail

        # Read subscription URL from secret
        SUBSCRIPTION_URL=$(cat /etc/sk/singbox/subscription_url)

        # Create config directory if it doesn't exist
        mkdir -p /Users/${myvars.username}/.config/sing-box

        # 临时文件，下载成功后再替换正式配置
        TEMP_CONFIG="/Users/${myvars.username}/.config/sing-box/config.json.tmp"
        CONFIG_FILE="/Users/${myvars.username}/.config/sing-box/config.json"

        echo "Downloading sing-box configuration from subscription URL..."

        # Download configuration with retry and timeout
        # curl 的重试机制比自己写 shell 循环更优雅
        ${pkgs.curl}/bin/curl -fsSL \
          --retry 3 \
          --retry-delay 5 \
          --retry-max-time 60 \
          --connect-timeout 30 \
          --max-time 120 \
          "$SUBSCRIPTION_URL" \
          -o "$TEMP_CONFIG"

        # Verify the downloaded file is valid JSON
        if ! ${pkgs.jq}/bin/jq empty "$TEMP_CONFIG" 2>/dev/null; then
          echo "Error: Downloaded configuration is not valid JSON"
          rm -f "$TEMP_CONFIG"
          exit 1
        fi

        # 原子性替换配置文件
        mv -f "$TEMP_CONFIG" "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"

        echo "Sing-box configuration updated successfully"
      '';
      mode = "0755";
    };

    # Launchd daemon to update sing-box configuration every 12 hours
    # 定时更新配置，与主服务解耦
    launchd.daemons.sing-box-update-config = {
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
