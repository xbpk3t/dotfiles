{
  config,
  pkgs,
  lib,
  myvars,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  cfg_path = "/tmp/sing-box/config.json";
in {
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box service";
  };

  # !!!
  # 1、注意这两个launchd 都需要作为 system级（而非用户级）
  ## - 保持 TUN 主服务为 system 级 daemon：创建 TUN 设备和路由需要 root，system 域的launchd 保证开机即生效且不受用户登录/退出影响。
  ## - “更新订阅”也可以继续放 system 级：它要读 sops secret（root 权限更自然），而且生成的 /tmp/sing-box/config.json 直接给 root 级 sing-box 用。
  # 2、本身这个singbox机制是很简单的。先用 update-config 把 config.json 拉到本地，然后直接 sing-box run -c config.json 跑起来即可。但是为了保证服务稳定可用，所以需要以下配置。
  config = mkIf cfg.enable {
    # Install sing-box package for user
    environment.systemPackages = [
      pkgs.sing-box
      pkgs.go-task
      pkgs.curl
      pkgs.jq
    ];

    # Launchd daemon: 调用 Taskfile 直接更新订阅配置
    # task -g singbox:update-config SINGBOX_URL="$(cat $HOME/.config/sops-nix/secrets/singboxUrl)" CONFIG_FILE="/tmp/sing-box/config.json"

    # task --taskfile $HOME/taskfile/mac/Taskfile.singbox.yml update-config SINGBOX_URL="$(cat $HOME/.config/sops-nix/secrets/singboxUrl)" CONFIG_FILE="/tmp/sing-box/config.json"

    # sudo launchctl list | rg singbox
    launchd.daemons.singbox-update-config = {
      serviceConfig = {
        Label = "local.singbox.update-config";
        # 使用 task CLI 运行 singbox:update-config，并把订阅 URL 作为参数传入
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''            CONFIG_FILE="${cfg_path}" \
                        SINGBOX_URL="$(cat ${config.sops.secrets.singboxUrl.path})" \
                        exec ${pkgs.go-task}/bin/task --taskfile /Users/${myvars.username}/taskfile/mac/Taskfile.singbox.yml update-config''
        ];

        # 开机后立即运行一次
        RunAtLoad = true;
        # 每 12 小时运行一次 (43200 秒)
        StartInterval = 43200;

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
          "${cfg_path}"
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
