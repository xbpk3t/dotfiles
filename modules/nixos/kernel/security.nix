{ lib, ... }:
{
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

      # 2026-10 eMudhra / Comodo AAA Services root 私钥泄露事件。
      # nixpkgs cacert 移除该根证书后删除本条目。
      # https://emudhra.we-have-a-problem.com/
      pki.caCertificateBlacklist = [ "Comodo AAA Services root" ];

      # sudo 留痕（追加到已存在的 extraConfig）
      sudo.extraConfig = lib.mkAfter ''
        Defaults logfile="/var/log/sudo.log"
      '';
    };

    # 默认关闭 systemd-coredump，避免生成大体积 core 文件
    systemd.coredump.enable = false;
  };
}
