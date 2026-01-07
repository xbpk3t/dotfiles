{
  config,
  pkgs,
  lib,
  myvars,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  servers = myvars.networking.singboxServers;
  secrets = {
    uuid = config.sops.placeholder.singbox_UUID;
    publicKey = config.sops.placeholder.singbox_pub_key;
    shortId = config.sops.placeholder.singbox_ID;
  };
  configJson = import ../../lib/singbox-config.nix (secrets // {inherit servers;});
  clientConfigPath = config.sops.templates."singbox-client.json".path;
in {
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box service";
  };

  # !!!
  # 1、注意这两个launchd 都需要作为 system级（而非用户级）
  ## - 保持 TUN 主服务为 system 级 daemon：创建 TUN 设备和路由需要 root，system 域的launchd 保证开机即生效且不受用户登录/退出影响。
  ## - “更新订阅”也可以继续放 system 级：它要读 sops secret（root 权限更自然），而且生成的 /var/lib/sing-box/config.json 直接给 root 级 sing-box 用。
  # 2、本身这个singbox机制是很简单的。先用 update-config 把 config.json 拉到本地，然后直接 sing-box run -c config.json 跑起来即可。但是为了保证服务稳定可用，所以需要以下配置。
  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.sing-box
    ];

    # 运行时渲染配置，避免密钥进入 /nix/store
    sops.templates."singbox-client.json".content = builtins.toJSON configJson;

    # sing-box TUN 代理服务 (需要 root 权限创建 TUN 接口)
    # 主服务只负责运行 sing-box，不再负责下载配置
    launchd.daemons.sing-box-tun = {
      serviceConfig = {
        Label = "local.singbox.tun";
        ProgramArguments = [
          "${pkgs.sing-box}/bin/sing-box"
          "run"
          "-c"
          "${clientConfigPath}"
        ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
          NetworkState = true;
        };
        # keep runtime artifacts (routes cache, crash dumps) alongside generated config
        # so the daemon never touches /tmp (which can be swept or have wrong perms)
        WorkingDirectory = "/var/lib/sing-box";
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
