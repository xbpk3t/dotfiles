{lib, ...}: let
  inherit (lib) mkEnableOption mkOption types;
in {
  options.modules.security.enableHighLimits = mkEnableOption ''
    启用高 ulimit 档（基于 Linux-Optimizer）：放宽 nofile/stack 等资源限制，适合高并发/压测/调试。
    默认关闭以保持安全基线（core=0）。
  '';

  options.modules.security.enableFirewall = mkOption {
    type = types.bool;
    default = true;
    description = ''
      是否启用主机防火墙。VPS 默认开启。
      适用于“私网 homelab 但仍需要 vps 模块”这类场景的显式关停。
    '';
  };

  config = {
    security = {
      # 基础安全基线（不含 AppArmor/SELinux）

      # 审计日志，记录关键安全事件
      auditd.enable = lib.mkDefault false;

      # /etc/login.defs 基线密码策略
      loginDefs = {
        # 仅 root/本用户/主组可改 GECOS
        chfnRestrict = "rwh";
        settings = {
          # 密码最大有效期（天）
          PASS_MAX_DAYS = 90;
          # 密码最小更改间隔（天）
          PASS_MIN_DAYS = 7;
          # 到期前提醒（天）
          PASS_WARN_AGE = 14;
          # 加密算法
          ENCRYPT_METHOD = "SHA512";
        };
      };

      # sudo 留痕（追加到已存在的 extraConfig）
      sudo.extraConfig = lib.mkAfter ''
        Defaults logfile="/var/log/sudo.log"
      '';
    };

    # 默认关闭 systemd-coredump，避免生成大体积 core 文件
    systemd.coredump.enable = false;
  };
}
