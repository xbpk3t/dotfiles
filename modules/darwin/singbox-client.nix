{
  config,
  pkgs,
  lib,
  mylib,
  userMeta,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  username = userMeta.username;
  client = import ../../lib/singbox/client-config.nix {
    inherit
      config
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
  # 1、注意这两个 launchd 都需要作为 system 级（而非 user 级）
  ## - 保持 TUN 主服务为 system daemon：创建 TUN interface 和注入 route 需要 root 权限。
  ## - 运行时读取 sops 渲染后的 config 也更适合走 system 域，避免和登录态绑定。
  # 2、Darwin 侧这里尽量只保留“最小管理层”：
  ## - 用 launchd 拉起 sing-box
  ## - 用 sops 渲染 runtime config
  ## - 不在这里叠加额外的 wake recover 逻辑，避免把“配置问题”和“恢复脚本问题”混在一起排查。
  #
  #
  #
  # [2026-01-24]
  #
  # 不清楚做了什么操作，导致 macOS 上的 sing-box 挂掉，status 显示
  # last exit code = 78: EX_CONFIG；执行 kickstart 时会直接卡住。
  # 但手动执行 sing-box run -c config.json 是可用的。
  #
  # 很明显，问题核心并不在 sing-box config 本身，而在 nix-darwin / launchd 的状态一致性：
  # job 状态卡在 “spawn scheduled / penalty box” 时，需要 bootout + bootstrap 重置。
  #
  # - launchctl bootout system /Library/LaunchDaemons/local.singbox.tun.plist
  # - launchctl bootstrap system /Library/LaunchDaemons/local.singbox.tun.plist
  #
  # 然后再 launchctl print 就能看到当前是 running 状态了。
  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.sing-box
    ];

    # 运行时渲染 config，避免 secret 进入 /nix/store。
    sops.templates."singbox-client.json".content = client.templatesContent;

    # sing-box TUN 代理服务：
    # - 只负责用最终渲染后的 config 启动 sing-box
    # - 不在 Darwin module 里额外承担订阅更新、wake repair 等职责
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
          # Why：只有在 network state 可用时才拉起 daemon，减少开机早期无网络的噪音失败。
          NetworkState = true;
        };
        # Why：把 runtime artifact 固定到 /var/lib/sing-box，避免落到 /tmp 后被系统清理。
        WorkingDirectory = "/var/lib/sing-box";
        StandardOutPath = "/Users/${username}/Library/Logs/sing-box.log";
        StandardErrorPath = "/Users/${username}/Library/Logs/sing-box.log";
        EnvironmentVariables = {
          PATH = "/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          # Darwin 下先保持 warn，避免 TUN 活跃时日志本身放大 CPU/I/O。
          SING_BOX_LOG_LEVEL = "warn";
        };
      };
    };
  };
}
