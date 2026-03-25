{
  config,
  lib,
  ...
}: let
  cfg = config.modules.systemd.manager.watchdog;
in {
  options.modules.systemd.manager.watchdog = with lib; {
    enable = mkEnableOption ''
      启用 systemd Manager watchdog 基线。
      注意：这里配置的是 systemd Manager 的 *WatchdogSec，不是 services.watchdogd。
    '';

    runtimeSec = mkOption {
      type = types.str;
      default = "15s";
      description = ''
        RuntimeWatchdogSec 的默认值。
        当底层 hardware/virtual watchdog 可用时，systemd 会按该周期喂狗；
        若系统长时间卡死未喂狗，firmware/hypervisor 可触发自动重启。
      '';
    };

    rebootSec = mkOption {
      type = types.str;
      default = "30s";
      description = ''
        RebootWatchdogSec 的默认值。
        用于 shutdown/reboot 流程长时间卡住时的兜底超时。
      '';
    };

    kexecSec = mkOption {
      type = types.str;
      default = "1m";
      description = ''
        KExecWatchdogSec 的默认值。
        用于 kexec 切换后系统无响应时的兜底超时。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # https://mynixos.com/nixpkgs/option/systemd.settings.Manager
    # 这里配置的是 systemd Manager 级别的 watchdog，而不是独立的 userspace watchdog daemon。
    # Why:
    # - 更适合无人值守 server/homelab 的“死机自愈”场景
    # - 由 PID 1 直接管理，语义比 services.watchdogd 更贴近系统级兜底
    systemd.settings.Manager = {
      # 运行中卡死保护：系统若长时间无法继续喂狗，可由底层 watchdog 强制拉起。
      RuntimeWatchdogSec = lib.mkDefault cfg.runtimeSec;
      # 重启/关机卡死保护：避免机器停在 stopping/rebooting 状态一直不可达。
      RebootWatchdogSec = lib.mkDefault cfg.rebootSec;
      # kexec 卡死保护：对使用 kexec 切换内核/系统的场景提供额外兜底。
      KExecWatchdogSec = lib.mkDefault cfg.kexecSec;
    };
  };
}
