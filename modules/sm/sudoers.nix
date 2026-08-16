# sm 轨 sudo 审计日志（基线能力：安全硬化必需，不做配置化开关）。
# vps-audit 的 Sudo Logging 检查项：grep "^Defaults.*logfile" /etc/sudoers。
# 这里用 sudoers.d drop-in 声明（NixOS 同款模式），distro sudo 的
# #includedir /etc/sudoers.d 自动读取。
_: {
  _file = ./sudoers.nix;

  # 日志写入 /var/log/sudo.log（sudo 自动 append，无需预建）。
  environment.etc."sudoers.d/99-sm-logging".text = ''
    Defaults logfile="/var/log/sudo.log"
  '';
}
