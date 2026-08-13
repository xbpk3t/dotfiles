# sm 轨 sshd 声明（安全版）。
# 警告：不要启用 services.openssh！上游该模块在 Debian 上会 mask 掉
# distro 的 ssh.service/ssh.socket 却不启动自己的 sshd（Phase 8 事故根因）。
#
# 安全方案：用 environment.etc 声明 sshd_config.d drop-in，由 distro sshd
# 读取（Debian sshd_config 默认 Include sshd_config.d/*.conf），
# 不接管服务单元 → 不 mask 不冲突，可反复 switch 收敛。
{ ... }:
{
  _file = ./sshd.nix;

  # 与 phase8-real.sh 手工硬化一致，但声明化。
  environment.etc."ssh/sshd_config.d/99-sm-hardening.conf".text = ''
    PermitRootLogin no
    PasswordAuthentication no
    KbdInteractiveAuthentication no
  '';

  # 说明：tailscaled / sshd 系统服务本身仍由 distro 管理，
  # sm 只声明配置 drop-in，避免 services.openssh 的 mask 事故。
}
