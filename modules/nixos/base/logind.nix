{...}: {
  # https://mynixos.com/nixpkgs/options/services.logind

  # Keep a minimal set of local VTs ready on every NixOS machine.
  services.logind.settings.Login = {
    # auto-spawn getty on tty1/tty2 only
    NAutoVTs = 2;
    # keep tty1 reserved so it's always usable
    ReserveVT = 1;

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
}
