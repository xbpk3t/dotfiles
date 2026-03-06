{
  config,
  pkgs,
  lib,
  myvars,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  client = import ../../lib/singbox/client-config.nix {
    inherit
      config
      myvars
      mylib
      lib
      pkgs
      ;
  };
  clientConfigPath = client.clientConfigPath;
in {
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box service";
  };

  # !!!
  # 1、注意这两个launchd 都需要作为 system级（而非用户级）
  ## - 保持 TUN 主服务为 system 级 daemon：创建 TUN 设备和路由需要 root，system 域的launchd 保证开机即生效且不受用户登录/退出影响。
  ## - “更新订阅”也可以继续放 system 级：它要读 sops secret（root 权限更自然），而且生成的 /var/lib/sing-box/config.json 直接给 root 级 sing-box 用。
  # 2、本身这个singbox机制是很简单的。先用 update-config 把 config.json 拉到本地，然后直接 sing-box run -c config.json 跑起来即可。但是为了保证服务稳定可用，所以需要以下配置。
  #
  #
  #
  # [2026-01-24]
  #
  # 不清楚做了什么操作，导致mac的sinbox挂了，status显示  last exit code = 78: EX_CONFIG，执行 kickstart 时，会直接卡住。直接手动执行 sing-box run config.json 就是可用的。但是 launchd 的 singbxo 就是起不来
  #
  # 很明显，还是nix-darwin的状态一致性问题
  #
  # 排查了半天，发现其实问题很明显，问题核心并不在于 singbox 配置问题（因为手动执行没问题），而在于 kickstart 卡住，卡住是因为 job 状态卡在“spawn scheduled/penalty box”，用 bootout + bootstrap 重置即可恢复。
  #
  # - launchctl bootout system /Library/LaunchDaemons/local.singbox.tun.plist
  # - launchctl bootstrap system /Library/LaunchDaemons/local.singbox.tun.plist
  #
  # 然后再 launchctl print 就能看到当前是running状态了
  #
  #
  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.sing-box
    ];

    # 运行时渲染配置，避免密钥进入 /nix/store
    sops.templates."singbox-client.json".content = client.templatesContent;

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
