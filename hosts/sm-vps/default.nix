# sm-vps group base：非 NixOS 系统态声明的共享基线。
#
# Node dirs import this and add role deltas:
#   tc -> dedicated VPS: sops + singbox/derper/status-page
#   hk -> shared VPS: modules.sm.shared = true, no global side effects
#
# 这里只放两个节点都需要的基线能力；服务角色和 shared 策略由节点自己声明。
{
  ...
}:
{
  imports = [
    # sm 模块树（基线能力直接 enable；服务角色读 modules.infra.*.enable）
    ../../modules/sm
  ];

  modules.sm = {
    fail2ban.enable = true;
    firewall.enable = true;
    gc.enable = true;
    managed-flag.enable = true;
    packages.enable = true;
    sshd.enable = true;
    systemd.enable = true;
    tailscale.enable = true;
  };
}
