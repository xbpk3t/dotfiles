{
  lib,
  pkgs,
  ...
}: {
  # https://mynixos.com/nixpkgs/options/services.logind

  # Keep a minimal set of local VTs ready on every NixOS machine.
  services.logind.settings.Login = {
    NAutoVTs = lib.mkDefault 2; # auto-spawn getty on tty1/tty2 only
    ReserveVT = lib.mkDefault 1; # keep tty1 reserved so it's always usable

    # 避免合盖挂起
    # 用 systemd 包住 systemd-inhibit 替换这种永久性nosleep方案

    # 1. 合盖不触发挂起
    #    HandleLidSwitch = "ignore";
    #    HandleLidSwitchExternalPower = "ignore";
    #    HandleLidSwitchDocked = "ignore";

    # 2. 不因为“空闲”去挂起
    #    IdleAction = "ignore";
    #    IdleActionSec = "0";

    # （可选）硬件挂起键也忽略掉，防止误触
    # HandleSuspendKey   = "ignore";
    # HandleHibernateKey = "ignore";
  };

  # nosleep service
  # 搭配shell直接使用
  systemd.services.nosleep = {
    description = "Prevent system from sleeping (nosleep)";

    # 支持 systemctl enable nosleep 做开机自启（不用就别 enable）
    wantedBy = ["multi-user.target"];

    unitConfig = {
      InhibitDelayMaxSec = 5;
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=sleep --why=nosleep-mode sleep infinity";
    };
  };
}
