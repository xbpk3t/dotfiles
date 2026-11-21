{
  config,
  lib,
  mylib,
  hostMeta,
  stateVersion,
  userMeta,
  ...
}:
let
  cfg = config.modules.wsl;
in
{
  # WSL host 的公共系统基线。只取 kernel 目录里与物理机无关的部分：
  # - user-group：创建 luck + sops 密码
  # - i18n：locale/timezone
  # - journald：日志策略
  # - openssh：sshd（WSL 内 Tailscale 节点/远程登录用）
  # 不要整目录导入 modules/nixos/kernel：zram.nix 无条件开 zram，
  # sysctl.nix 是 VPS 专用，core.nix 假设 bootloader。
  imports = map mylib.relativeToRoot [
    "modules/nixos/kernel/user-group.nix"
    "modules/nixos/kernel/i18n.nix"
    "modules/nixos/kernel/journald.nix"
    "modules/nixos/kernel/openssh.nix"
    "modules/nixos/infra/nix-tools.nix"
    "modules/nixos/infra/tailscale-client.nix"
  ];

  options.modules.wsl = {
    graphics.enable = lib.mkEnableOption "WSLg graphics (mesa/llvm) on this WSL host";

    maxJobs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = "Nix max-jobs for this WSL host.";
    };

    cores = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = "Nix cores per job for this WSL host.";
    };
  };

  config = {
    # NixOS-WSL 负责 systemd、/etc/wsl.conf 和 Windows interop。
    wsl = {
      enable = true;
      defaultUser = userMeta.username;

      # /mnt/c 的文件按 uid 1001 呈现，和 luck 的固定 UID 对齐，
      # 避免 Windows 侧创建/移动过来的 repo 触发 git "dubious ownership"。
      # 注意：WSLg 的 /mnt/wslg/runtime-dir 仍由 WSL 以 uid 1000 创建；
      # CLI host 默认关 graphics，需要 WSLg 时再处理该目录属主或改用 uid 1000。
      wslConf.automount.options = lib.mkDefault "metadata,uid=1001,gid=100";
    };

    networking = {
      hostName = lib.mkDefault hostMeta.hostName;
      # WSL 自己生成 /etc/resolv.conf；NixOS-WSL 的 generateResolvConf
      # 已经关闭 NixOS 侧 resolvconf，不需要 useHostResolvConf。
    };

    # NixOS-WSL 模块默认强制打开 hardware.graphics（WSLg）。
    # CLI host 默认关闭；需要 WSLg 的 host 设 modules.wsl.graphics.enable = true。
    hardware.graphics.enable = lib.mkForce cfg.graphics.enable;

    system.stateVersion = lib.mkDefault stateVersion;
    # WSL 生命周期由 Windows 管，不启用定时升级。
    system.autoUpgrade.enable = lib.mkForce false;

    # 固定 UID 1001（官方 release 的 nixos 用户占用 1000，且
    # users.mutableUsers=false 会在首次 switch 删除它）；automount 的 uid 已对齐。
    users.users.${userMeta.username}.uid = 1001;

    modules = {
      kernel = {
        journald.enable = true;
        openssh.enable = true;
      };
      infra.nix-tools = {
        enable = true;
        gc = {
          keepGenerations = 3;
          maxAge = "7d";
          dates = "daily";
        };
      };
      # 所有 WSL host 默认作为 tailnet client；不需要的 host 可显式关掉。
      networking.tailscale.enable = lib.mkDefault true;
    };

    # PA 只有 8GB RAM；构建时限制并发，避免 OOM。公司机器可按需覆盖。
    nix.settings = {
      max-jobs = lib.mkForce cfg.maxJobs;
      cores = lib.mkForce cfg.cores;
    };
  };
}
