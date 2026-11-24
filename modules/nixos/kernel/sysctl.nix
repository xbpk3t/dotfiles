{
  config,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.kernel.sysctl;
  sysctl =
    (
      if cfg.hardware == null then
        # 无 hardware profile 时的保守基线；显式策略选项在下面统一叠加，
        # 否则没有 profile 的 host（例如 nixos-usb）设了策略会被静默忽略。
        mylib.vpsSysctl.mkDefaultSysctl
      else
        mylib.vpsSysctl.mkSysctl (cfg.hardware // { zramEnabled = config.zramSwap.enable; })
    )
    // mylib.vpsSysctl.mkMemoryPolicy {
      inherit (cfg) oomKillAllocatingTask overcommitMemory;
    };
in
{
  options.modules.kernel.sysctl = {
    hardware = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      description = ''
        VPS hardware/network profile used to derive kernel sysctl.
        Set this in the host module; leave null to use the default tuning.
        Known fields: cpuCores, memGiB, bwMbps, rttMs, mode, cc, qdisc, isSsd.
      '';
    };

    oomKillAllocatingTask = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether the kernel should kill the task that triggered the OOM
        (vm.oom_kill_allocating_task=1) instead of the highest oom_score task.
        Defaults to false; build-heavy hosts may opt in.
      '';
    };

    overcommitMemory = lib.mkOption {
      type = lib.types.ints.between 0 2;
      default = 1;
      description = ''
        Value for vm.overcommit_memory. 0 = heuristic, 1 = always overcommit,
        2 = strict accounting. Kept at 1 by default because Nix builds fork
        heavily; pair with cgroup memory limits on small hosts.
      '';
    };
  };

  # 模块里已有 `options`，其它配置必须放进显式 `config`。
  config = {
    # VPS 专用：根据 host module 提供的 hardware profile 动态生成 sysctl。
    # mkForce 确保覆盖 nixpkgs 默认 sysctl（如 fs.inotify.max_user_instances），
    # 避免在容器等叠加上下文中出现 "defined multiple times" 错误。
    boot.kernel.sysctl = lib.mkForce sysctl;

    # systemd-sysctl 晚于 systemd-modules-load；显式加载 nf_conntrack，
    # 否则 net.netfilter.nf_conntrack_* 会被静默跳过。
    boot.kernelModules = [ "nf_conntrack" ];
  };
}
