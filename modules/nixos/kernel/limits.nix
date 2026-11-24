# PAM 登录资源限制（limits.conf / pam_limits）。
#
# 这不是内核 sysctl：它控制每个登录用户/进程的 RLIMIT_*。
# 默认档位与 sysctl mode 共用同一个硬件事实 `hostMeta.hardware.memGiB`，
# 由 lib/hardware-profile.nix 统一派生；host 仍可显式覆盖 profile。
{
  config,
  hostMeta,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.kernel.limits;
  memGiB = hostMeta.hardware.memGiB or null;
  derived = mylib.hardwareProfile.profileFor memGiB;

  # 保守基线：禁止 core dump，避免敏感内存落盘。
  baseline = [
    {
      domain = "*";
      type = "hard";
      item = "core";
      value = "0";
    }
  ];

  # 高负载/构建/调试主机档。数值保持有界：
  # - core 仍为 0（需要 core dump 时再单独加 debug profile）
  # - memlock 64 GiB（limits.conf 的 memlock 单位是 KB）
  # - nproc 65536，避免 fork bomb 拖死整机
  # - rss 不设置：现代内核已不强制 RLIMIT_RSS
  high = [
    {
      domain = "*";
      type = "-";
      item = "core";
      value = "0";
    }
    {
      domain = "*";
      type = "-";
      item = "data";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "-";
      item = "fsize";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "-";
      item = "sigpending";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "-";
      item = "memlock";
      value = "67108864";
    }
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = "1048576";
    }
    {
      domain = "*";
      type = "-";
      item = "msgqueue";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "-";
      item = "stack";
      value = "32768";
    }
    {
      domain = "*";
      type = "hard";
      item = "stack";
      value = "65536";
    }
    {
      domain = "*";
      type = "-";
      item = "cpu";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "-";
      item = "nproc";
      value = "65536";
    }
    {
      domain = "*";
      type = "-";
      item = "as";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "-";
      item = "locks";
      value = "unlimited";
    }
  ];
in
{
  options.modules.kernel.limits = {
    enable = lib.mkEnableOption "PAM login resource limits";

    profile = lib.mkOption {
      type = lib.types.enum [
        "baseline"
        "high"
      ];
      default = derived.limits;
      description = ''
        `baseline` keeps core dumps disabled (core=0).
        `high` raises per-process limits for high-concurrency/build/debug
        workstations; it remains bounded (memlock 64 GiB, nproc 65536).
        Defaults from hostMeta.hardware.memGiB via lib/hardware-profile.nix.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    security.pam.loginLimits = if cfg.profile == "high" then high else baseline;
  };
}
