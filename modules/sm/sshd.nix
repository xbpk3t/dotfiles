# sm 轨 sshd 声明（S1 骨架，S2 白名单加厚时填充）。
# 上游 system-manager 自带 services.openssh（NixOS 模块适配），
# 因此可直接声明 services.openssh.settings，无需手写 systemd unit。
# 注意：不 import modules/nixos/kernel/openssh.nix（那是 NixOS 模块，需 osConfig）。
{ ... }:
{
  _file = ./sshd.nix;

  # S2 TODO：声明 sshd 硬化（如 settings.PasswordAuthentication = false）。
  # services.openssh = {
  #   enable = true;
  #   settings.PasswordAuthentication = false;
  #   settings.PermitRootLogin = "no";
  # };
}
