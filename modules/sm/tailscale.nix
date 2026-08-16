# sm 轨 tailscale 声明。
#
# 背景：上游 system-manager 无 services.tailscale 模块（未适配 NixOS 的 tailscale）。
# tailscale 系统服务（tailscaled）由 bootstrap 官方 install script 安装管理
# （/usr/bin/tailscale + /etc/systemd/system/tailscaled.service），登录态在
# /var/lib/tailscale。sm 不接管 tailscaled 本体（避免 unmanaged path 冲突，
# 符合「系统层尽量薄」哲学）——本模块只声明 exit node 的**广告**这一件事。
#
# 原理：tailscale set --advertise-exit-node 是幂等且持久化的 daemon 偏好
# （写进 /var/lib/tailscale 的 daemon 状态，重启不丢）。所以只需一个 oneshot
# 在每次 sm switch 时把它再确认一遍；tailscaled 未就绪时命令失败也不应阻塞
# 激活（用 systemd `-` 前缀忽略退出码），避免触发 magicRollback 误伤。
#
# 授权侧（谁被允许走这个出口）归 TF 的 tailscale_acl 控制面管，本模块不管。
# 已确认：infra/stacks/homelab/tailscale/tailnet/locals.tf 的 autoApprovers
# + grants 只放行 nod-am（手机），保持现状。
_: {
  _file = ./tailscale.nix;

  # exit node 需要 IP 转发。boot 时由 systemd-sysctl 应用；oneshot 里再跑一次
  # /sbin/sysctl --system 立即生效（不重启也生效）。
  environment.etc."sysctl.d/99-sm-tailscale.conf".text = ''
    net.ipv4.ip_forward = 1
    net.ipv6.conf.all.forwarding = 1
  '';

  systemd.services.sm-tailscale-exitnode = {
    enable = true;
    description = "Advertise sm-vps as Tailscale exit node (idempotent)";
    wantedBy = [ "system-manager.target" ];
    after = [
      "network.target"
      "systemd-sysctl.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "/sbin/sysctl --system"
        "-/usr/bin/tailscale set --advertise-exit-node=true"
      ];
    };
  };
}
