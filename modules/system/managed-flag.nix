# 可验证系统态：/etc/sm-vps-managed + 简单 oneshot unit（幂等 switch 证明）。
# 不接 tailscale/sshd——容器内网络/sshd 易踩坑；flag 文件足够验收 T2。
{
  pkgs,
  lib,
  ...
}:
{
  _file = ./managed-flag.nix;

  environment.etc."sm-vps-managed" = {
    mode = "0644";
    text = ''
      # Managed by system-manager (sm-vps Phase 4 T2). Do not edit by hand.
      node=sm-vps-lab
      role=sm-vps
      phase=4
      marker=sm-vps-managed
    '';
  };

  # 可选：证明 systemd unit 收敛；oneshot + RemainAfterExit，无常驻进程。
  systemd.services.sm-vps-managed-marker = {
    enable = true;
    description = "sm-vps Phase 4 managed marker (oneshot)";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe' pkgs.coreutils "true"}";
    };
    wantedBy = [ "system-manager.target" ];
  };
}
