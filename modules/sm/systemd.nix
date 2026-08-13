# sm 轨 systemd 配置（journald + logind 等）。
# 映射自 modules/nixos/kernel/{journald,logind}.nix，但用 sm 能力面表达：
#   NixOS 的 services.journald / services.logind.settings → environment.etc 写
#   /etc/systemd/*.conf.d/ drop-in（distro systemd 自动读取）。
# 保持与 nixos 轨同语义，不接管服务单元、不 mask。
#
# 这是 sm-vps 基线能力（日志/会话管理必需），不做配置化开关。
{ ... }:
{
  _file = ./systemd.nix;

  # ── journald：日志策略（持久化 + 空间上限 + 轮转）──
  # 对应 NixOS services.journald（modules/nixos/kernel/journald.nix）
  environment.etc."systemd/journald.conf.d/99-sm.conf".text = ''
    [Journal]
    Storage=persistent
    Compress=yes
    Seal=yes
    SplitMode=uid
    SystemMaxUse=1G
    SystemKeepFree=512M
    SystemMaxFileSize=128M
    MaxFileSec=1day
    MaxRetentionSec=14day
    RateLimitIntervalSec=30s
    RateLimitBurst=10000
    SyncIntervalSec=5m
    LineMax=48K
    ReadKMsg=yes
  '';

  # ── logind：会话管理（保留最小 VT；合盖/空闲不挂起注释保留可开关）──
  # 对应 NixOS services.logind（modules/nixos/kernel/logind.nix）
  environment.etc."systemd/logind.conf.d/99-sm.conf".text = ''
    [Login]
    NAutoVTs=2
    ReserveVT=1
    # HandleLidSwitch=ignore        # 合盖不挂起（VPS 无意义，注释保留）
    # IdleAction=ignore             # 空闲不挂起
  '';
}
