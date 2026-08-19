{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.infra.avahi;
in
{
  options.modules.infra.avahi = {
    enable = lib.mkEnableOption "avahi-daemon (mDNS local network discovery)";
  };

  # 开放 mDNS (`avahi-daemon`) 方便局域网发现 | 公网 VPS 默认不需要广播自身，暴露 mDNS 反而增加攻击面
  # mDNS 仅在 Desktop 启用
  config = lib.mkIf cfg.enable {
    # Network discovery on a local network, mDNS
    # With this enabled, you can access your machine at <hostname>.local
    # it's more convenient than using the IP address.
    # https://avahi.org/
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        domain = true;
        userServices = true;
      };
    };
  };
}
