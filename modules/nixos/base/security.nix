{...}: {
  # https://mynixos.com/nixpkgs/options/security

  # 基础安全基线（不含 AppArmor/SELinux）
  #
  #  # 开启主机防火墙，具体放行端口在 modules/nixos/base/networking/firewall.nix
  #  networking.firewall.enable = lib.mkForce true;
  #
  #  # 内核与进程隔离相关的安全 sysctl
  #  boot.kernel.sysctl = {
  #    "kernel.dmesg_restrict" = lib.mkDefault 1; # 仅 root 可读 dmesg
  #    "kernel.kptr_restrict" = lib.mkDefault 2;   # 隐藏内核指针
  #    "kernel.yama.ptrace_scope" = lib.mkDefault 1; # 禁止跨用户 ptrace
  #    "fs.protected_hardlinks" = lib.mkDefault 1; # 防止硬链接提权
  #    "fs.protected_symlinks" = lib.mkDefault 1;  # 防止符号链接攻击
  #    # 如果关闭 systemd-coredump，则使用普通 core 文件名
  #    "kernel.core_pattern" = lib.mkDefault "core";
  #  };
  #
  #  security = {
  #    # 审计日志，记录关键安全事件
  #    auditd.enable = lib.mkDefault true;
  #
  #    # /etc/login.defs 基线密码策略
  #    loginDefs = {
  #      chfnRestrict = lib.mkDefault "rwh"; # 仅 root/本用户/主组可改 GECOS
  #      settings = {
  #        PASS_MAX_DAYS = lib.mkDefault 90;
  #        PASS_MIN_DAYS = lib.mkDefault 7;
  #        PASS_WARN_AGE = lib.mkDefault 14;
  #        ENCRYPT_METHOD = lib.mkDefault "SHA512";
  #      };
  #    };
  #
  #    # sudo 留痕（追加到已存在的 extraConfig）
  #    sudo.extraConfig = lib.mkAfter ''
  #      Defaults logfile="/var/log/sudo.log"
  #    '';
  #  };
  #
  #  # 默认关闭 systemd-coredump，避免生成大体积 core 文件
  #  systemd.coredump.enable = lib.mkDefault false;
}
